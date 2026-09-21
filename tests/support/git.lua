local M = {}

---Run git in the current directory, asserting it succeeded.
---@param args string[]
---@return string
function M.git(args)
  local out = vim.fn.system(vim.list_extend({ "git" }, args))
  assert(vim.v.shell_error == 0, out)
  return vim.trim(out)
end

---Create a temp directory and enter it.
---@return string tmp, string previous The directory Neovim was in before.
function M.tempdir()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local previous = vim.fn.chdir(tmp)
  assert(previous ~= "", "could not enter the fixture directory")
  return tmp, previous
end

---Initialise a repo on `branch` with one empty commit, and return its SHA.
---@param branch string
---@return string
function M.init_repo(branch)
  M.git({ "init", "-q", "-b", branch })
  -- Refuse to go further unless git resolved to the fixture. Everything below
  -- writes commits and config, and a stray GIT_* var pointing elsewhere would
  -- land them in a real repo.
  local root = vim.fn.resolve(M.git({ "rev-parse", "--show-toplevel" }))
  assert(root == vim.fn.resolve(vim.fn.getcwd()), "fixture git repo escaped to " .. root)

  M.git({ "config", "user.email", "test@example.com" })
  M.git({ "config", "user.name", "Test" })
  M.git({ "config", "commit.gpgsign", "false" })
  M.git({ "commit", "-q", "--allow-empty", "-m", "base" })
  return M.git({ "rev-parse", "HEAD" })
end

return M
