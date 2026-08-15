local M = {}

---Split `zoxide query --list` output into a list of directory paths.
---Blank/whitespace-only lines are dropped; each line is trimmed.
---@param output string Raw stdout from zoxide.
---@return string[]
local function parse(output)
  local dirs = {}
  for line in output:gmatch("[^\n]+") do
    local dir = vim.trim(line)
    if dir ~= "" then
      dirs[#dirs + 1] = dir
    end
  end
  return dirs
end
M._parse = parse

---Query zoxide for known directories, most-frecent first.
---@return string[]
local function list()
  local out = vim.fn.system({ "zoxide", "query", "--list" })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return parse(out)
end

---Switch projects by quitting Neovim so the fish wrapper relaunches it in `dir`.
---We only change nvim's cwd indirectly: the target is stashed in a global and
---written to $NVIM_CWD_FILE on VimLeavePre, then the shell wrapper cd's + reopens.
---`:confirm qall` so unsaved buffers prompt, exactly like a real `:qa`.
---@param dir string
local function switch(dir)
  vim.g.projects_switch_target = dir
  vim.cmd("confirm qall")
end

---Open a picker of zoxide directories; selecting one switches projects.
function M.open()
  local dirs = list()
  if #dirs == 0 then
    vim.notify("projects: zoxide returned no directories", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fs.normalize(vim.fn.getcwd())

  vim.ui.select(dirs, {
    prompt = "Projects",
    -- Show ~ for $HOME and mark the current working directory.
    format_item = function(dir)
      local mark = (vim.fs.normalize(dir) == cwd) and "● " or "  "
      return mark .. vim.fn.fnamemodify(dir, ":~")
    end,
  }, function(dir)
    if dir then
      switch(dir)
    end
  end)
end

---Arm the exit hook that hands the chosen directory to the fish wrapper.
function M.setup()
  -- Fires just before Neovim exits. If a project was picked (target set) and the
  -- wrapper provided a drop file, write the target there so the shell cd's into
  -- it and relaunches nvim. Armed on the actual quit, so a cancelled :qa writes
  -- nothing.
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("projects", { clear = true }),
    callback = function()
      local target = vim.g.projects_switch_target
      local drop = vim.env.NVIM_CWD_FILE
      if not target or not drop or drop == "" then
        return
      end
      local fd = io.open(drop, "w")
      if fd then
        fd:write(target)
        fd:close()
      end
    end,
  })
end

return M
