---Opens the current file's copy from another worktree of the same repository.
local M = {}

---@class worktrunk.Worktree
---@field path string
---@field branch? string Nil when HEAD is detached.

---Split `git worktree list --porcelain` output into worktrees.
---@param porcelain string
---@return worktrunk.Worktree[]
local function parse(porcelain)
  local trees = {}
  for line in porcelain:gmatch("[^\n]+") do
    local path = line:match("^worktree (.+)$")
    local branch = line:match("^branch refs/heads/(.+)$")
    if path then
      trees[#trees + 1] = { path = path }
    elseif branch then
      trees[#trees].branch = branch
    end
  end
  return trees
end
M._parse = parse

-- git reports worktrees by physical path, which on macOS can differ from the
-- path a buffer was opened by (/var vs /private/var).
---@param path string
---@return string
local function real(path)
  return vim.uv.fs_realpath(path) or path
end

---Pick another worktree, then run `cmd` on the current file's copy in it.
---@param cmd string Ex command taking a file name, such as "vsplit".
local function with_copy(cmd)
  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.bo.buftype == "" and file ~= "" and vim.fs.root(file, ".git") or nil
  if not root then
    vim.notify("worktrunk: this buffer isn't a file in a git worktree", vim.log.levels.WARN)
    return
  end
  -- Unresolved on both sides, so a symlink is found by the link's own path.
  local rel = assert(vim.fs.relpath(root, file))
  local listed = vim.system({ "git", "-C", root, "worktree", "list", "--porcelain" }, { text = true }):wait()
  if listed.code ~= 0 then
    vim.notify("worktrunk: " .. vim.trim(listed.stderr or ""), vim.log.levels.ERROR)
    return
  end
  local here = real(root)
  local others = vim.tbl_filter(function(tree)
    return real(tree.path) ~= here
  end, parse(listed.stdout or ""))
  if #others == 0 then
    vim.notify("worktrunk: no other worktrees", vim.log.levels.WARN)
    return
  end

  vim.ui.select(others, {
    prompt = rel .. " in",
    format_item = function(tree)
      return (tree.branch or "(detached)") .. "  " .. vim.fn.fnamemodify(tree.path, ":~")
    end,
  }, function(tree)
    if not tree then
      return
    end
    local copy = vim.fs.joinpath(tree.path, rel)
    if not vim.uv.fs_stat(copy) then
      vim.notify(("worktrunk: %s isn't in %s"):format(rel, tree.branch or tree.path), vim.log.levels.WARN)
      return
    end
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(copy))
  end)
end

---Open the current file's copy from another worktree in a vertical split.
function M.split()
  with_copy("vsplit")
end

---Diff the current file against its copy in another worktree.
function M.diff()
  with_copy("vertical diffsplit")
end

return M
