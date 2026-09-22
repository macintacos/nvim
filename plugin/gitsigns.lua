-- github.com/lewis6991/gitsigns.nvim
-- Git change indicators in the sign column
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup()

-- PR Review Mode points gitsigns' base at this branch's fork point from the
-- default branch, so the gutter marks everything the branch changed rather than
-- just uncommitted work. It turns itself on off the default branch; `:PRReview`
-- turns it off, and each branch remembers that choice for the session.

---@type table<string, true> Branches the mode was switched off on.
local dismissed = {}

---@type string? Branch the global base was last resolved for.
local applied

-- Relies on gitsigns internals: its buffer cache, each buffer's
-- `git_obj.revision`, and non-global `change_base` resolving the current buffer
-- before it yields.

---@type string? Base every buffer should diff against; nil is the index.
local want

---@type table<string, true> Bases this file has applied.
local ours = {}

local pending = false

---@return boolean
local function is_on()
  return want ~= nil
end

---Whether a buffer's base is this file's to move: hand-set and fugitive bases are not.
---@param revision string?
---@return boolean
local function owned(revision)
  return revision == nil or ours[revision] == true
end

---Move buffers that missed the base, such as ones attached mid-walk.
local function reconcile()
  -- Buffers attaching mid-walk may be visited by the walk too; moving them here
  -- as well moves them twice. The walk's callback runs this once it ends.
  if pending then
    return
  end
  for buf, bcache in pairs(require("gitsigns.cache").cache) do
    local have = bcache.git_obj.revision
    if have ~= want and owned(have) then
      vim.api.nvim_buf_call(buf, function()
        require("gitsigns").change_base(want)
      end)
    end
  end
end

---Point every owned buffer at `base`.
---@param base string?
---@param done fun(err: string?)?
local function apply(base, done)
  want = base
  if base then
    ours[base] = true
  end
  -- The repo watcher refreshes each buffer right after GitSignsUpdate, reading
  -- this field then and writing it back when the refresh lands.
  for _, bcache in pairs(require("gitsigns.cache").cache) do
    if owned(bcache.git_obj.revision) then
      bcache.git_obj.revision = base
    end
  end
  pending = true
  require("gitsigns").change_base(base, true, function(err)
    pending = false
    reconcile()
    if done then
      done(err)
    end
  end)
end

---Diff against the fork point from the default branch.
---@param report boolean Announce success; failures announce regardless.
local function enable(report)
  local base, branch = require("helpers.git").merge_base()
  if not base then
    vim.notify("PR Review Mode: no merge base with the default branch", vim.log.levels.WARN)
    return
  end
  apply(base, function(err)
    if err then
      vim.notify("PR Review Mode: " .. err, vim.log.levels.ERROR)
    elseif report then
      vim.notify("PR Review Mode: on (vs " .. branch .. ")")
    end
  end)
end

---Follow a branch change. Re-resolves the base even when the mode is already
---on, since the fork point belongs to the branch that was left behind.
---@param branch string
local function sync(branch)
  if branch == applied then
    return
  end
  applied = branch
  if dismissed[branch] or branch == require("helpers.git").default_base() then
    if is_on() then
      apply(nil)
    end
  else
    enable(false)
  end
end

vim.api.nvim_create_user_command("PRReview", function()
  local branch = vim.b.gitsigns_head or ""
  if is_on() then
    apply(nil)
    dismissed[branch] = true
    vim.notify("PR Review Mode: off")
  else
    dismissed[branch] = nil
    enable(true)
  end
end, { desc = "Toggle PR Review Mode for this branch" })

-- gitsigns republishes a buffer's branch on every sign refresh, including after
-- a checkout made outside Neovim, so this doubles as a branch-change hook, and
-- each event also moves buffers that missed the base. Its
-- cwd-wide sibling event carries no buffer and is skipped: that watcher never
-- starts in a worktree, where `.git` is a file rather than a directory.
vim.api.nvim_create_autocmd("User", {
  pattern = "GitSignsUpdate",
  callback = function(args)
    local branch = args.data and vim.b[args.data.buffer].gitsigns_head
    if branch and branch ~= "" then
      sync(branch)
    end
    reconcile()
  end,
})
