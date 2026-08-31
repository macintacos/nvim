local M = {}

---Fraction of the editor the float covers, per axis.
local FLOAT_SCALE = 0.8

---Path to the current project's scratch file, creating `.tmp/` and the file
---itself if they don't exist yet.
---@return string path Absolute path to `<cwd>/.tmp/scratch.md`.
local function ensure_file()
  local dir = vim.fs.joinpath(vim.fn.getcwd(), ".tmp")
  vim.fn.mkdir(dir, "p")
  local path = vim.fs.joinpath(dir, "scratch.md")
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
  return path
end
M._ensure_file = ensure_file

---Open the scratch file in the current window.
function M.open()
  vim.cmd.edit(vim.fn.fnameescape(ensure_file()))
end

---Find a float in the current tabpage already showing `buf`.
---@param buf integer Buffer handle.
---@return integer? win Window handle, or nil when no such float is open.
local function find_float(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local floating = vim.api.nvim_win_get_config(win).relative ~= ""
    if floating and vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end
M._find_float = find_float

---Open the scratch file in a centered float covering 80% of the editor.
---Focuses the existing float instead of stacking a second one on top.
function M.float()
  local buf = vim.fn.bufadd(ensure_file())
  vim.fn.bufload(buf)

  local open = find_float(buf)
  if open then
    vim.api.nvim_set_current_win(open)
    return
  end

  local width = math.floor(vim.o.columns * FLOAT_SCALE)
  local height = math.floor(vim.o.lines * FLOAT_SCALE)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " .tmp/scratch.md ",
    title_pos = "center",
  })
end

return M
