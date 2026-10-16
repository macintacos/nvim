---Moves Neovim into the primary worktree once the linked worktree it is in is
---removed, so nothing that reads the working directory finds it gone.
local M = {}

local watcher = assert(vim.uv.new_fs_event())

---The directory the latest `watch()` was asked to watch.
---@type string?
local watched

local rescued = false

---`:cd` into `primary` if `dir` is gone and still the one being watched.
---@param dir string
---@param primary string
local function rescue(dir, primary)
  if watched ~= dir or vim.uv.fs_stat(dir) then
    return
  end
  rescued = true
  vim.cmd.cd(vim.fn.fnameescape(primary))
  vim.notify(("%s was removed; now in %s"):format(vim.fn.fnamemodify(dir, ":~"), vim.fn.fnamemodify(primary, ":~")))
end

---Watch `dir` for its removal when it sits in a linked worktree.
---@param dir string
local function watch(dir)
  watcher:stop()
  watched = dir
  local argv = { "git", "rev-parse", "--path-format=absolute", "--git-dir", "--git-common-dir" }
  vim.system(argv, { cwd = dir, text = true }, function(res)
    local git_dir, common_dir = (res.stdout or ""):match("^(.-)\n(.-)\n$")
    -- A primary worktree's git dir is the common one.
    if watched ~= dir or not common_dir or git_dir == common_dir then
      return
    end
    local primary = vim.fs.dirname(common_dir)
    watcher:start(
      dir,
      {},
      vim.schedule_wrap(function()
        rescue(dir, primary)
      end)
    )
  end)
end

---Whether Neovim has been moved out of a removed worktree.
---@return boolean
function M.rescued()
  return rescued
end

---Whether a linked worktree is being watched.
---@return boolean
function M._armed()
  return watcher:is_active() == true
end

---Watch the working directory now and after every `:cd`.
function M.setup()
  -- Moves the removal watch to the new working directory. Fires: after `:cd`;
  -- `:lcd` and `:tcd` leave it on the global one.
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("worktrunk.rescue", { clear = true }),
    pattern = "global",
    callback = function()
      watch(vim.fn.getcwd(-1, -1))
    end,
  })
  watch(vim.fn.getcwd(-1, -1))
end

return M
