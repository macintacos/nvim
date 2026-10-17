-- github.com/nanozuki/tabby.nvim
-- Tabline of tab pages, not buffers: each tab's number and the icon and name of the file
-- its focused window shows. tabby's tab_only layout, drawn flat so the current tab joins
-- the winbar below; vim.pack's update review stands out as a green pill.
vim.pack.add(
  { { src = "https://github.com/nanozuki/tabby.nvim", version = vim.version.range("2.x") } },
  { load = false }
)

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
---@return TabbyNode
local function file_icon(buf, current)
  local icon, icon_hl = MiniIcons.get("file", vim.api.nvim_buf_get_name(buf))
  if not current then
    return icon
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

---@param tab TabbyTab
---@return TabbyElement
local function tab_label(tab)
  local tabid = tab.id --[[@as integer]]
  local current = tab.is_current()
  local buf = vim.api.nvim_win_get_buf(labeled_win(tabid))
  local jump_key = tab.in_jump_mode() and { tab.jump_key(), hl = "FlashLabel" }
  if is_pack_review(buf) then
    -- The statusline's update count shows the same plug.
    return { " ", jump_key or tab.number(), "  ", tab.name(), " ", hl = current and "TabbyPackSel" or "TabbyPack" }
  end
  local number = jump_key or { tab.number(), hl = current and "TabbyNumberSel" or nil }
  local name_hl = has_unsaved(tabid) and (current and "TabbyUnsavedSel" or "TabbyUnsaved") or nil
  return {
    " ",
    number,
    " ",
    file_icon(buf, current),
    " ",
    { tab.name(), hl = name_hl },
    " ",
    hl = current and "TabLineSel" or "TabLine",
  }
end

vim.schedule(function()
  vim.cmd.packadd("tabby.nvim")
  -- The default rather than a line option, so <leader><tab>'s tab list names tabs alike.
  require("tabby.feature.tab_name").set_default_option({
    name_fallback = function(tabid)
      return default_name(tabid --[[@as integer]])
    end,
  })
  require("tabby").setup({
    line = function(line)
      -- The spacer switches back to the fill, or the last tab's colors run to the edge.
      return { line.tabs().foreach(tab_label), line.spacer(), hl = "TabLineFill" }
    end,
  })
end)
