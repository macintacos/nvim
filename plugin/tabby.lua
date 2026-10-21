-- github.com/nanozuki/tabby.nvim
-- Tabline of tab pages, not buffers: rounded tabs sized to their names, centered together,
-- each showing its number, file icon and file name. vim.pack's update review and scratch
-- files stand out in colors of their own.
vim.pack.add({ { src = "https://github.com/nanozuki/tabby.nvim", version = vim.version.range("2.x") } })

-- nf-ple-left_half_circle_thick and _right_: a tab's rounded ends.
local LEFT_CAP, RIGHT_CAP = vim.fn.nr2char(0xE0B6), vim.fn.nr2char(0xE0B4)

-- Bounds on a tab's width in cells, its rounded ends included.
local MIN_TAB_WIDTH, MAX_TAB_WIDTH = 25, 70

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

---A tab's name until it is renamed: the file its labeled window shows, or "Changeset"
---for changeset.nvim's sidebar, whose buffer has no file name.
---@param tabid integer
---@return string
local function default_name(tabid)
  local win = labeled_win(tabid)
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].filetype == "changeset" then
    return "Changeset"
  end
  local look = require("helpers.tabs").special(buf)
  return look and look.name or require("tabby.feature.win_name").get(win)
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

---What a tab shows, before it is fitted to a width.
---@class tabby.Label
---@field prefix tabby.Part[]
---@field name tabby.Part
---@field hl string

---Cells `prefix` takes, a space after each part included.
---@param prefix tabby.Part[]
---@return integer
local function prefix_width(prefix)
  local used = #prefix
  for _, part in ipairs(prefix) do
    used = used + vim.api.nvim_strwidth(part[1])
  end
  return used
end

---`label`'s prefix and name spaced apart and centered in `width` cells, the name shortened
---to leave a cell either side.
---@param label tabby.Label
---@param width integer
---@return TabbyElement
local function centered(label, width)
  local name = label.name
  local used = prefix_width(label.prefix)
  name[1] = shorten(name[1], width - used - 2)
  used = used + vim.api.nvim_strwidth(name[1])
  local left = math.max(math.floor((width - used) / 2), 0)
  local node = { string.rep(" ", left), hl = label.hl }
  for _, part in ipairs(label.prefix) do
    vim.list_extend(node, { part, " " })
  end
  vim.list_extend(node, { name, string.rep(" ", math.max(width - used - left, 0)) })
  return node
end

---@param tab TabbyTab
---@return tabby.Label
local function tab_label(tab)
  local tabid = tab.id --[[@as integer]]
  local current = tab.is_current()
  local buf = vim.api.nvim_win_get_buf(labeled_win(tabid))
  local look = require("helpers.tabs").special(buf)
  local nr = tab.number()
  local number = tab.in_jump_mode() and { tab.jump_key(), hl = "FlashLabel" }
    or { require("helpers.tabs").number_box(nr), hl = current and not look and "TabbyNumberSel" or nil }
  if look then
    return { prefix = { number, { look.icon } }, name = { tab.name() }, hl = current and look.hl_sel or look.hl }
  end
  local name_hl = has_unsaved(tabid) and (current and "TabbyUnsavedSel" or "TabbyUnsaved") or nil
  return {
    prefix = { number, file_icon(buf, current) },
    name = { tab.name(), hl = name_hl },
    hl = current and "TabLineSel" or "TabLine",
  }
end

---Cells a tab needs to show `label` whole, with a cell either side and its rounded ends,
---kept within MIN_TAB_WIDTH and MAX_TAB_WIDTH.
---@param label tabby.Label
---@return integer
local function tab_width(label)
  local whole = prefix_width(label.prefix) + vim.api.nvim_strwidth(label.name[1]) + 4
  return math.max(MIN_TAB_WIDTH, math.min(whole, MAX_TAB_WIDTH))
end

---The widest a tab may be for tabs of `widths` to fit in `room` cells: tabs narrower than
---that keep their width, and the rest share what those leave.
---@param widths integer[]
---@param room integer
---@return integer
local function width_cap(widths, room)
  local sorted = vim.list_slice(widths)
  table.sort(sorted)
  for i, width in ipairs(sorted) do
    local share = math.floor(room / (#sorted - i + 1))
    if width > share then
      return share
    end
    room = room - width
  end
  return sorted[#sorted]
end

---`label` between rounded ends in its background, so the tab reads as a pill.
---@param line TabbyLine
---@param label TabbyElement
---@return TabbyElement
local function pill(line, label)
  local hl = label.hl --[[@as string]]
  if not vim.api.nvim_get_hl(0, { name = hl, link = false }).bg then
    return label
  end
  return { line.sep(LEFT_CAP, hl, "TabLineFill"), label, line.sep(RIGHT_CAP, hl, "TabLineFill") }
end

---Every tab as a pill sized to its label, with a cell between each.
---@param line TabbyLine
---@return TabbyNode
local function pills(line)
  local tabs = line.tabs()
  local labels = vim.tbl_map(tab_label, tabs.tabs)
  local widths = vim.tbl_map(tab_width, labels)
  local cap = width_cap(widths, vim.o.columns - (#widths - 1))
  return tabs.foreach(function(_, i)
    i = i --[[@as integer]]
    return pill(line, centered(labels[i], math.min(widths[i], cap) - 2))
  end, { margin = " " })
end

-- The default rather than a line option, so <leader>t's tab list names tabs alike.
require("tabby.feature.tab_name").set_default_option({
  name_fallback = function(tabid)
    return default_name(tabid --[[@as integer]])
  end,
})
require("tabby").setup({
  line = function(line)
    return { line.spacer(), pills(line), line.spacer(), hl = "TabLineFill" }
  end,
})
