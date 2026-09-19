local Git = require("helpers.git")

---Run git in the current directory, asserting it succeeded.
---@param args string[]
---@return string
local function git(args)
  local out = vim.fn.system(vim.list_extend({ "git" }, args))
  assert(vim.v.shell_error == 0, out)
  return vim.trim(out)
end

---Initialise a repo on `branch` with one empty commit, and return its SHA.
---@param branch string
---@return string
local function init_repo(branch)
  git({ "init", "-q", "-b", branch })
  -- Refuse to go further unless git resolved to the fixture. Everything below
  -- writes commits and config, and a stray GIT_* var pointing elsewhere would
  -- land them in a real repo.
  local root = vim.fn.resolve(git({ "rev-parse", "--show-toplevel" }))
  assert(root == vim.fn.resolve(vim.fn.getcwd()), "fixture git repo escaped to " .. root)

  git({ "config", "user.email", "test@example.com" })
  git({ "config", "user.name", "Test" })
  git({ "config", "commit.gpgsign", "false" })
  git({ "commit", "-q", "--allow-empty", "-m", "base" })
  return git({ "rev-parse", "HEAD" })
end

describe("helpers.git", function()
  local tmp, cwd, git_env

  before_each(function()
    -- Git hooks export GIT_DIR and friends, and those override cwd-based repo
    -- discovery — under `pre-push` the fixtures below would otherwise operate
    -- on the repo being pushed.
    git_env = {}
    for name, value in pairs(vim.fn.environ()) do
      if name:match("^GIT_") then
        git_env[name] = value
        vim.env[name] = nil
      end
    end

    tmp = vim.fn.tempname()
    vim.fn.mkdir(tmp, "p")
    cwd = vim.fn.chdir(tmp)
    assert(cwd ~= "", "could not enter the fixture directory")
  end)

  after_each(function()
    vim.fn.chdir(cwd)
    vim.fn.delete(tmp, "rf")
    for name, value in pairs(git_env) do
      vim.env[name] = value
    end
  end)

  describe("default_base", function()
    it("picks the conventional branch that exists", function()
      init_repo("trunk")
      assert.equal("trunk", Git.default_base())
    end)

    it("prefers origin/HEAD over the conventional names", function()
      init_repo("main")
      git({ "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/mainline" })
      assert.equal("mainline", Git.default_base())
    end)

    it("falls back to main when nothing matches", function()
      init_repo("weird")
      assert.equal("main", Git.default_base())
    end)
  end)

  describe("merge_base", function()
    it("returns the fork point and the branch it forked from", function()
      local fork = init_repo("trunk")
      git({ "checkout", "-q", "-b", "feature" })
      git({ "commit", "-q", "--allow-empty", "-m", "work" })

      local sha, branch = Git.merge_base()
      assert.equal(fork, sha)
      assert.equal("trunk", branch)
    end)

    it("returns nil outside a repo", function()
      assert.is_nil(Git.merge_base())
    end)
  end)
end)
