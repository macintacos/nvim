---Git queries shared across plugin configs.
local M = {}

---Run a git command and return its stdout lines, or an empty table if it failed.
---@param args string[] Command and arguments, run without a shell.
---@return string[]
function M.lines(args)
  local out = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return out
end

---Resolve the repo's default branch: origin/HEAD's target, else the first of
---main/master/trunk that exists, else "main".
---@return string branch Short name, with any remote prefix stripped.
function M.default_base()
  local head = M.lines({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })[1]
  if head then
    return (head:gsub("^origin/", ""))
  end
  for _, name in ipairs({ "main", "master", "trunk" }) do
    if #M.lines({ "git", "rev-parse", "--verify", "--quiet", name }) > 0 then
      return name
    end
  end
  return "main"
end

---Resolve the commit where HEAD forked from the default branch.
---@return string? sha nil outside a repo, or when the two share no ancestor.
---@return string? branch The default branch the fork point was taken against.
function M.merge_base()
  local branch = M.default_base()
  -- origin/ first: a local default branch sitting behind the remote drags the
  -- fork point backwards, showing already-merged commits as this branch's work.
  for _, ref in ipairs({ "origin/" .. branch, branch }) do
    local sha = M.lines({ "git", "merge-base", "HEAD", ref })[1]
    if sha then
      return sha, branch
    end
  end
end

return M
