---Drives worktrunk (`wt`) from a terminal float, then relaunches Neovim in
---whichever worktree it leaves the shell in.
local M = {}

---Open a centered float on a fresh buffer that is wiped once the float closes.
---@param title string
---@return integer win
local function open_float(title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  return require("helpers.windows").open_centered_float(buf, title)
end

---Read and delete the file a command reported its final directory in.
---@param path string
---@return string? dir Nil when the command never reported one.
local function read_landed(path)
  local fd = io.open(path)
  if not fd then
    return nil
  end
  local dir = vim.trim(fd:read("*a"))
  fd:close()
  os.remove(path)
  return dir ~= "" and dir or nil
end

---@param buf integer
---@return boolean
local function has_output(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false)):find("%S") ~= nil
end

---Run `argv` in a terminal float. When it ends somewhere other than Neovim's
---cwd, close the float and relaunch Neovim there; when it stays put, close the
---float unless it left output to read, which any key then dismisses.
---@param title string
---@param argv string[] Writes the physical path of the directory it ends in to `$NVIM_WT_LANDED`.
local function run(title, argv)
  local start = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.getcwd()
  local landed_file = vim.fn.tempname()
  local win = open_float(title)
  local buf = vim.api.nvim_win_get_buf(win)
  vim.fn.jobstart(argv, {
    term = true,
    env = { NVIM_WT_LANDED = landed_file },
    on_exit = function()
      local landed = read_landed(landed_file)
      if landed == start then
        landed = nil
      end
      if (landed or not has_output(buf)) and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if not landed then
        return
      end
      -- The switch quits Neovim, so getting past it means the quit was
      -- cancelled or failed, as saving into a removed worktree does.
      local ok, err = pcall(require("plugins.projects").switch, landed)
      if not vim.uv.fs_stat(start) then
        vim.notify(
          ("worktrunk: %s is gone; save what you need elsewhere, then quit"):format(start),
          vim.log.levels.WARN
        )
      elseif not ok then
        vim.notify("worktrunk: " .. tostring(err), vim.log.levels.ERROR)
      end
    end,
  })
  vim.cmd.startinsert()
end
M._run = run

---Argv that runs `command` in an interactive fish, the only shell where
---`__wt_pick` and wt's directory-changing `wt` wrapper are defined, then
---reports where the shell ended up.
---@param command string
---@return string[]
local function fish(command)
  return { "fish", "-i", "-c", command .. '; pwd -P >"$NVIM_WT_LANDED"' }
end
M._fish = fish

---Warn and return false while a file buffer holds unsaved changes, which would
---be stranded once wt removes the worktree under them.
---@return boolean
local function all_saved()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "" and vim.bo[buf].modified then
      vim.notify("worktrunk: save or discard your unsaved changes first", vim.log.levels.WARN)
      return false
    end
  end
  return true
end

---@param question string
---@return boolean
local function confirmed(question)
  return vim.fn.confirm(question, "&Yes\n&No", 2) == 1
end

---Open the fish worktree picker the shell binds to `<C-t>`.
function M.pick()
  run("worktrees", fish("__wt_pick"))
end

---Switch to the previously visited worktree.
function M.previous()
  run("wt switch -", fish("wt switch -"))
end

---Switch to the default branch's worktree.
function M.default_branch()
  run("wt switch ^", fish("wt switch ^"))
end

---Remove the current worktree, once confirmed, and land in the primary one.
function M.remove()
  local here = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  if all_saved() and confirmed(("Remove the worktree at %s?"):format(here)) then
    run("wt remove", fish("wt remove"))
  end
end

---Merge the current branch into the default branch, once confirmed, then
---remove its worktree and land in the target's.
function M.merge()
  local here = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  if all_saved() and confirmed(("Merge %s into the default branch and remove its worktree?"):format(here)) then
    run("wt merge", fish("wt merge"))
  end
end

---Follow Neovim out of any linked worktree removed from under it.
function M.setup()
  require("plugins.worktrunk.rescue").setup()
end

return M
