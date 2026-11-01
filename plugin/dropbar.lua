-- github.com/Bekaboo/dropbar.nvim
-- Breadcrumb navigation bar
vim.pack.add({ "https://github.com/Bekaboo/dropbar.nvim" })

local utils = require("dropbar.utils")

---Close the open submenu, or with none open, swap this segment's menu for the one
---before it in the winbar. The first segment's menu stays open.
local function step_out()
  local menu = utils.menu.get_current()
  if not menu then
    return
  end
  if menu.prev_menu then
    menu:close()
    return
  end
  -- By buffer too: the menu's preview has swapped another buffer into the window.
  local bar = utils.bar.get({ buf = menu.prev_buf, win = menu.prev_win }) --[[@as dropbar_t?]]
  if not bar then
    return
  end
  for idx, segment in ipairs(bar.components) do
    if segment.menu == menu and idx > 1 then
      menu:close()
      bar:pick(idx - 1)
      return
    end
  end
end

---Open the submenu of the row under the cursor. Unlike <CR>, never jumps to a row.
local function descend()
  local menu = utils.menu.get_current()
  local entry = menu and menu.entries[vim.api.nvim_win_get_cursor(0)[1]]
  -- A row's first component is the submenu arrow, clickable only when the row has children.
  local arrow = entry and entry.components[1]
  if menu and arrow and arrow.on_click then
    menu:click_on(arrow, nil, 1, "l")
  end
end

---Close every menu level, back to the window the winbar belongs to.
local function leave()
  local menu = utils.menu.get_current()
  local root = menu and menu:root()
  if root then
    root:close()
  end
end

---@type integer?
local preview_win

---The first `height` lines of the file at `path`, or a directory's entries.
---@param path string
---@param height integer
---@return string[]
local function preview_lines(path, height)
  if vim.fn.isdirectory(path) == 1 then
    return vim.fn.readdir(path)
  end
  local ok, lines = pcall(vim.fn.readfile, path, "", height)
  if not ok then
    return { "Unreadable file" }
  end
  -- readfile() turns NUL bytes into newlines inside a line.
  if table.concat(lines):find("\n", 1, true) then
    return { "Binary file" }
  end
  return lines
end

---Highlight `buf` as the file at `path`, without the FileType autocmds that would attach LSP.
---@param buf integer
---@param path string
local function preview_highlight(buf, path)
  local ft = vim.filetype.match({ filename = path })
  local lang = ft and vim.treesitter.language.get_lang(ft)
  if not (lang and pcall(vim.treesitter.start, buf, lang)) then
    vim.bo[buf].syntax = ft or ""
  end
end

---Show the file or directory at `path` in a float filling the editor's bottom-right quarter.
---@param path string
local function show_preview(path)
  local config = {
    relative = "editor",
    anchor = "SE",
    -- Above the statusline and the command line.
    row = vim.o.lines - vim.o.cmdheight - 1,
    col = vim.o.columns,
    width = math.floor(vim.o.columns / 2),
    height = math.floor(vim.o.lines / 2),
    style = "minimal",
    focusable = false,
    -- Under the menus, which take the default 50.
    zindex = 40,
    title = " " .. vim.fs.basename(path) .. " ",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, preview_lines(path, config.height))
  preview_highlight(buf, path)
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_set_buf(preview_win, buf)
    vim.api.nvim_win_set_config(preview_win, config)
  else
    preview_win = vim.api.nvim_open_win(buf, false, vim.tbl_extend("force", config, { noautocmd = true }))
  end
end

-- Closes the preview float once the last breadcrumb menu closes. When a submenu closes
-- into its parent instead, it previews the parent's row under the cursor, which the
-- float would otherwise leave showing the submenu's last row.
vim.api.nvim_create_autocmd("WinClosed", {
  group = vim.api.nvim_create_augroup("dropbar_preview", { clear = true }),
  callback = vim.schedule_wrap(function()
    -- Until a menu opens, dropbar has no menu registry for get_current() to read.
    if not (preview_win and vim.api.nvim_win_is_valid(preview_win)) then
      return
    end
    local menu = utils.menu.get_current()
    if menu then
      menu:preview_symbol_at(vim.api.nvim_win_get_cursor(0), true)
    else
      vim.api.nvim_win_close(preview_win, true)
      preview_win = nil
    end
  end),
})

-- dropbar_configs_t declares every key required, but setup() deep-merges this onto its defaults.
---@diagnostic disable-next-line: missing-fields, param-type-mismatch
require("dropbar").setup({
  sources = {
    path = {
      -- Declines dropbar's own preview, which swaps a scratch buffer into the window
      -- and blanks its winbar, after drawing the file in our float instead.
      preview = function(path)
        show_preview(path)
        return false
      end,
    },
  },
  menu = {
    keymaps = {
      h = step_out,
      l = descend,
      ["<Esc>"] = leave,
    },
  },
})
