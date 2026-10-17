-- github.com/nanozuki/tabby.nvim
-- Tabline of tab pages, not buffers: the tabs share the width equally, each centering
-- its number, file icon and file name. The current tab joins the winbar below; vim.pack's
-- update review stands out in green.
vim.pack.add({ { src = "https://github.com/nanozuki/tabby.nvim", version = vim.version.range("2.x") } })

-- nf-md-numeric_1_box through _9_box, as herdr numbers its panes; 5's box breaks the
-- codepoints' stride of 3.
local NUMBER_BOXES = vim.tbl_map(vim.fn.nr2char, {
  0xF03A4,
  0xF03A7,
  0xF03AA,
  0xF03AD,
  0xF03B1,
  0xF03B3,
  0xF03B6,
  0xF03B9,
  0xF03BC,
})

-- nf-fa-plug, the statusline's update count icon.
local PLUG = vim.fn.nr2char(0xF1E6)

---@alias tabby.Part { [1]: string, hl: TabbyHighlight? }

---@param win integer
---@return boolean
local function is_float(win)
  return vim.api.nvim_win_get_config(win).relative ~= ""
end

---The window a tab's label names: its focused one, or while a float such as a picker
---has focus, the window the float was entered from.
---@param tabid integer
---@return integer
local function labeled_win(tabid)
  local win = vim.api.nvim_tabpage_get_win(tabid)
  if not is_float(win) then
    return win
  end
  local nr = vim.api.nvim_tabpage_get_number(tabid)
  local prev = vim.fn.win_getid(vim.fn.tabpagewinnr(nr, "#"), nr)
  if prev ~= 0 and not is_float(prev) then
    return prev
  end
  -- Floats sit at the end of the window list.
  return vim.api.nvim_tabpage_list_wins(tabid)[1] --[[@as integer]]
end

---Whether the buffer is vim.pack's update review (`vim.pack.update()`'s confirmation).
---@param buf integer
---@return boolean
local function is_pack_review(buf)
  return vim.bo[buf].filetype == "nvim-pack"
end

---A tab's name until it is renamed: the file its labeled window shows.
---@param tabid integer
---@return string
local function default_name(tabid)
  local win = labeled_win(tabid)
  if is_pack_review(vim.api.nvim_win_get_buf(win)) then
    return "Plugin Updates"
  end
  return require("tabby.feature.win_name").get(win)
end

---The buffer's file icon: in its own color on the current tab, muted with the label on
---the others.
---@param buf integer
---@param current boolean
---@return tabby.Part
local function file_icon(buf, current)
  local icon, icon_hl = MiniIcons.get("file", vim.api.nvim_buf_get_name(buf))
  if not current then
    return { icon }
  end
  local fg = vim.api.nvim_get_hl(0, { name = icon_hl, link = false }).fg
  local bg = vim.api.nvim_get_hl(0, { name = "TabLineSel", link = false }).bg
  return { icon, hl = { fg = fg, bg = bg } }
end

---Whether a window in the tab shows a buffer with unsaved changes.
---@param tabid integer
---@return boolean
local function has_unsaved(tabid)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabid)) do
    if not is_float(win) and vim.bo[vim.api.nvim_win_get_buf(win)].modified then
      return true
    end
  end
  return false
end

---`text` cut to `width` cells, ending in "…" when cut.
---@param text string
---@param width integer
---@return string
local function shorten(text, width)
  if vim.api.nvim_strwidth(text) <= width then
    return text
  end
  local chars = vim.fn.strchars(text)
  while chars > 0 and vim.api.nvim_strwidth(vim.fn.strcharpart(text, 0, chars)) >= width do
    chars = chars - 1
  end
  return width > 0 and vim.fn.strcharpart(text, 0, chars) .. "…" or ""
end

---`prefix` and `name` spaced apart and centered in `width` cells, the name shortened to
---leave a cell either side.
---@param prefix tabby.Part[]
---@param name tabby.Part
---@param width integer
---@param hl string
---@return TabbyElement
local function centered(prefix, name, width, hl)
  local used = #prefix
  for _, part in ipairs(prefix) do
    used = used + vim.api.nvim_strwidth(part[1])
  end
  name[1] = shorten(name[1], width - used - 2)
  used = used + vim.api.nvim_strwidth(name[1])
  local left = math.max(math.floor((width - used) / 2), 0)
  local node = { string.rep(" ", left), hl = hl }
  for _, part in ipairs(prefix) do
    vim.list_extend(node, { part, " " })
  end
  vim.list_extend(node, { name, string.rep(" ", math.max(width - used - left, 0)) })
  return node
end

---@param tab TabbyTab
---@return TabbyElement
local function tab_label(tab)
  local tabid = tab.id --[[@as integer]]
  local current = tab.is_current()
  local buf = vim.api.nvim_win_get_buf(labeled_win(tabid))
  local pack = is_pack_review(buf)
  local nr, count = tab.number(), vim.fn.tabpagenr("$")
  -- Tab n of N spans columns ⌊W(n-1)/N⌋ to ⌊Wn/N⌋, which together fill W exactly.
  local width = math.floor(vim.o.columns * nr / count) - math.floor(vim.o.columns * (nr - 1) / count)
  local number = tab.in_jump_mode() and { tab.jump_key(), hl = "FlashLabel" }
    or { NUMBER_BOXES[nr] or tostring(nr), hl = current and not pack and "TabbyNumberSel" or nil }
  if pack then
    return centered({ number, { PLUG } }, { tab.name() }, width, current and "TabbyPackSel" or "TabbyPack")
  end
  local name_hl = has_unsaved(tabid) and (current and "TabbyUnsavedSel" or "TabbyUnsaved") or nil
  return centered(
    { number, file_icon(buf, current) },
    { tab.name(), hl = name_hl },
    width,
    current and "TabLineSel" or "TabLine"
  )
end

-- The default rather than a line option, so <leader>t's tab list names tabs alike.
require("tabby.feature.tab_name").set_default_option({
  name_fallback = function(tabid)
    return default_name(tabid --[[@as integer]])
  end,
})
require("tabby").setup({
  line = function(line)
    return { line.tabs().foreach(tab_label), hl = "TabLineFill" }
  end,
})
