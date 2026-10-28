local git = require("support.git")
local refs = require("plugins.branches.refs")

---@param branches branches.Branch[]
---@return string[]
local function names(branches)
  return vim.tbl_map(function(b)
    return b.name
  end, branches)
end

---@param branches branches.Branch[]
---@param name string
---@return branches.Branch
local function find(branches, name)
  for _, b in ipairs(branches) do
    if b.name == name then
      return b
    end
  end
  error("no branch named " .. name)
end

describe("branches.refs.parse", function()
  ---@type string
  local root
  ---@type string
  local repo

  before_each(function()
    root = vim.fn.tempname()
    repo = root .. "/repo"
    vim.fn.mkdir(repo, "p")
    git.git({ "init", "-q", "--bare", "-b", "trunk", root .. "/remote.git" }, root)
    git.init_repo("trunk", repo)
    git.git({ "remote", "add", "origin", root .. "/remote.git" }, repo)
    git.git({ "push", "-q", "-u", "origin", "trunk" }, repo)
    git.git({ "push", "-q", "origin", "trunk:refs/heads/feature", "trunk:refs/heads/remote-only" }, repo)
    git.git({ "fetch", "-q", "origin" }, repo)
    git.git({ "remote", "set-head", "origin", "trunk" }, repo)
    git.git({ "branch", "feature" }, repo)
    git.git({ "worktree", "add", "-q", "-b", "held", root .. "/held" }, repo)
    vim.fn.writefile({ "ahead" }, repo .. "/file")
    git.commit("ahead", repo)
  end)

  after_each(function()
    vim.fn.delete(root, "rf")
  end)

  ---@return branches.Branch[]
  local function parse()
    return refs.parse(git.git(refs.ARGS, repo))
  end

  it("lists the current branch first, then the other local branches, then the remote-only ones", function()
    local branches = parse()
    assert.are.equal(find(branches, "trunk"), branches[1])
    assert.are.same("current", find(branches, "trunk").kind)
    assert.are.same({ "feature", "held" }, vim.fn.sort(names({ branches[2], branches[3] })))
    assert.are.same({ "origin/remote-only" }, names({ branches[4] }))
    assert.are.equal(4, #branches)
  end)

  it("drops origin/HEAD and every remote branch with a local one of the same name", function()
    local remotes = vim.tbl_filter(function(b)
      return b.kind == "remote"
    end, parse())
    assert.are.same({ "origin/remote-only" }, names(remotes))
  end)

  it("marks a branch checked out in another worktree with that worktree's path", function()
    local held = find(parse(), "held")
    assert.are.same("worktree", held.kind)
    assert.are.same(vim.fn.resolve(root .. "/held"), vim.fn.resolve(held.worktree or ""))
  end)

  it("reads how far a branch stands from its upstream", function()
    local trunk = find(parse(), "trunk")
    assert.are.same({ 1, 0, false }, { trunk.ahead, trunk.behind, trunk.gone })
    local feature = find(parse(), "feature")
    assert.are.same({ 0, 0, false }, { feature.ahead, feature.behind, feature.gone })
  end)

  it("marks a branch whose upstream is gone", function()
    git.git({ "branch", "-q", "-u", "origin/remote-only", "feature" }, repo)
    git.git({ "push", "-q", "origin", "--delete", "remote-only" }, repo)
    git.git({ "fetch", "-q", "--prune", "origin" }, repo)
    assert.is_true(find(parse(), "feature").gone)
  end)

  it("carries each branch's ref and last commit", function()
    local remote = find(parse(), "origin/remote-only")
    assert.are.same("refs/remotes/origin/remote-only", remote.ref)
    assert.are.same({ "Test", "root" }, { remote.author, remote.subject })
    assert.is_true(math.abs(os.time() - remote.time) < 60)
  end)
end)

describe("branches.refs.age", function()
  it("counts the largest whole unit that fits", function()
    assert.are.same(
      { "now", "5m", "3h", "2d", "3w", "4mo", "2y" },
      vim.tbl_map(refs.age, { 30, 300, 3 * 3600 + 59, 2 * 86400, 21 * 86400, 125 * 86400, 800 * 86400 })
    )
  end)
end)
