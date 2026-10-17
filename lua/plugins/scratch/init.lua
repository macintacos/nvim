local M = {}

---@class scratch.Item
---@field text string Name shown in the picker.
---@field path? string Absolute path; nil only on the entry that creates a file.

---@return string dir Absolute path to `<cwd>/.tmp/scratch`.
local function scratch_dir()
  return vim.fs.joinpath(vim.fn.getcwd(), ".tmp", "scratch")
end

---Scratch files in `dir` as picker items, most recently modified first.
---@param dir string
---@return scratch.Item[] items
local function list(dir)
  local items = {}
  for name in vim.fs.dir(dir) do
    items[#items + 1] = { text = name, path = vim.fs.joinpath(dir, name) }
  end
  table.sort(items, function(a, b)
    return vim.fn.getftime(a.path) > vim.fn.getftime(b.path)
  end)
  return items
end

---First of `scratch.md`, `scratch-2.md`, `scratch-3.md`, … not taken in `dir`.
---@param dir string
---@return string name
local function next_name(dir)
  local name, n = "scratch.md", 1
  while vim.uv.fs_stat(vim.fs.joinpath(dir, name)) do
    n = n + 1
    name = ("scratch-%d.md"):format(n)
  end
  return name
end

---Path to the scratch file `name` in `dir`, creating it if it doesn't exist.
---An empty name takes the next free `scratch-<n>.md`; a name without an
---extension gets `.md`.
---@param dir string
---@param name string
---@return string path
local function ensure(dir, name)
  if name == "" then
    name = next_name(dir)
  elseif vim.fn.fnamemodify(name, ":e") == "" then
    name = name .. ".md"
  end
  local path = vim.fs.joinpath(dir, name)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  if vim.fn.filereadable(path) == 0 then
    vim.fn.writefile({}, path)
  end
  return path
end

---Pick a scratch file, or name a new one, and hand its path to `show`. With
---no scratch file yet, creates `scratch.md` without asking.
---@param show fun(path: string)
local function choose(show)
  local dir = scratch_dir()
  local files = list(dir)
  if #files == 0 then
    show(ensure(dir, ""))
    return
  end

  MiniPick.start({
    source = {
      name = "Scratch",
      items = vim.list_extend({ { text = "+ New scratch file" } }, files),
      show = function(buf_id, items, query)
        MiniPick.default_show(buf_id, items, query, { show_icons = true })
      end,
      ---@param item scratch.Item
      preview = function(buf_id, item)
        if item.path then
          MiniPick.default_preview(buf_id, item)
        end
      end,
      ---@param item scratch.Item
      choose = function(item)
        -- The picker is still open while this runs. Act once it has closed and
        -- focus is back in the window it was opened from, so a float opened
        -- here returns focus there when it closes.
        vim.schedule(function()
          if item.path then
            show(item.path)
            return
          end
          vim.ui.input({ prompt = "Scratch name: " }, function(name)
            if name then
              show(ensure(dir, name))
            end
          end)
        end)
      end,
    },
    window = require("plugins.mini-pickers.preview").window(),
  })
end

---Pick a scratch file and open it in the current window.
function M.open()
  choose(function(path)
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
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

---Show `path` in a centered float covering 80% of the editor, focusing the
---float already showing it instead of stacking a second one on top.
---@param path string
local function show_float(path)
  local buf = vim.fn.bufadd(path)
  vim.fn.bufload(buf)

  local open = find_float(buf)
  if open then
    vim.api.nvim_set_current_win(open)
    return
  end

  require("helpers.windows").open_centered_float(buf, vim.fn.fnamemodify(path, ":."))
end

---Pick a scratch file and open it in a centered float.
function M.float()
  choose(show_float)
end

---Show `path` in a new tab, or go to a window already showing it in any tab.
---@param path string
local function show_tab(path)
  local win = vim.fn.win_findbuf(vim.fn.bufadd(path))[1]
  if win then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd.tabedit(vim.fn.fnameescape(path))
  end
end

---Pick a scratch file and open it in a new tab.
function M.tab()
  choose(show_tab)
end

---Whether `path` is a scratch file of any project, not just the current one.
---@param path string
---@return boolean
function M.is_scratch(path)
  return path:find("/.tmp/scratch/", 1, true) ~= nil
end

return M
