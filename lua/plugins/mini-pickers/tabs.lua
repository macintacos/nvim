---A picker over the open tabs that can also open a new one.
---
---It hangs just under the tabline, centered and sized to its rows, and each row
---reads like a tab on the tabline: its number box, file icon and name.

local M = {}

local NS = vim.api.nvim_create_namespace("mini_pick_tabs")

-- nf-md-tab_plus, which-key's New Tab icon.
local NEW_TAB = vim.fn.nr2char(0xF075C)

-- Room for the prompt and the footer's name and count however short the names are.
local MIN_WIDTH = 30

---@class tabs.Row
---@field text string What the row shows and the query matches.
---@field tab integer? The tab it switches to; nil on the New Tab row.
---@field hls { [1]: integer, [2]: integer, [3]: string }[] `{ from, to, group }` byte ranges in `text`.

---`parts` spaced apart, each colored in its group when it has one.
---@param parts { [1]: string, [2]: string? }[]
---@param tab integer?
---@return tabs.Row
local function row(parts, tab)
  local texts, hls, col = {}, {}, 0
  for _, part in ipairs(parts) do
    texts[#texts + 1] = part[1]
    if part[2] then
      hls[#hls + 1] = { col, col + #part[1], part[2] }
    end
    col = col + #part[1] + 1
  end
  return { text = table.concat(texts, " "), tab = tab, hls = hls }
end

---Whether a window in `tab` shows a buffer with unsaved changes.
---@param tab integer
---@return boolean
local function unsaved(tab)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].modified then
      return true
    end
  end
  return false
end

---A row per tab in `tabs`, named as the tabline names it, then the New Tab row.
---@param tabs integer[]
---@param current integer The tab the picker opens over.
---@return tabs.Row[]
function M._rows(tabs, current)
  local tab_name = require("tabby.feature.tab_name")
  local helpers = require("helpers.tabs")
  local rows = vim.tbl_map(function(tab)
    local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tab))
    local box =
      { helpers.number_box(vim.api.nvim_tabpage_get_number(tab)), tab == current and "MiniPickTabCurrent" or "Comment" }
    local look = helpers.special(buf)
    if look then
      return row({ box, { look.icon, look.hl_list }, { tab_name.get(tab), look.hl_list } }, tab)
    end
    local icon, icon_hl = MiniIcons.get("file", vim.api.nvim_buf_get_name(buf))
    return row({ box, { icon, icon_hl }, { tab_name.get(tab), unsaved(tab) and "MiniPickTabUnsaved" or nil } }, tab)
  end, tabs)
  -- The blank part keeps "New Tab" level with the names, past the icon column.
  rows[#rows + 1] = row({ { NEW_TAB, "Comment" }, { " " }, { "New Tab", "Comment" } })
  return rows
end

---`source.show`: mini.pick's own rendering, then each row's colors.
---@param buf integer
---@param rows tabs.Row[]
---@param query string[]
local function show(buf, rows, query)
  MiniPick.default_show(buf, rows, query)
  vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
  for i, r in ipairs(rows) do
    for _, hl in ipairs(r.hls) do
      -- Under mini.pick's match (200) and current row (201) marks, so both still show.
      vim.api.nvim_buf_set_extmark(buf, NS, i - 1, hl[1], { end_col = hl[2], hl_group = hl[3], priority = 199 })
    end
  end
end

---@param r tabs.Row
local function choose(r)
  -- The picker hands focus back to the window it opened from as it closes,
  -- which would undo a switch made while it is still up.
  vim.schedule(function()
    if r.tab then
      vim.api.nvim_set_current_tabpage(r.tab)
    else
      vim.cmd.tabnew()
    end
  end)
end

---The picker's float: just under the tabline, centered, one line per row.
---@param rows tabs.Row[]
---@return vim.api.keyset.win_config
local function window(rows)
  local width = MIN_WIDTH
  for _, r in ipairs(rows) do
    width = math.max(width, vim.api.nvim_strwidth(r.text) + 1)
  end
  width = math.min(width, vim.o.columns - 2)
  local tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and #rows > 2)
  return {
    anchor = "NW",
    row = tabline and 1 or 0,
    col = math.floor((vim.o.columns - width - 2) / 2),
    width = width,
    height = #rows,
  }
end

---Pick a tab to switch to, or the last row to open a new one.
function M.pick()
  local current = vim.api.nvim_get_current_tabpage()
  local rows = M._rows(vim.api.nvim_list_tabpages(), current)
  -- Starts the picker on the current tab rather than the first. Fires once, as
  -- the picker comes up: the first moment its selection can be set.
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniPickStart",
    once = true,
    callback = function()
      MiniPick.set_picker_match_inds({ vim.api.nvim_tabpage_get_number(current) }, "current")
    end,
  })
  MiniPick.start({
    source = { name = "Tabs", items = rows, show = show, choose = choose },
    window = { config = window(rows) },
  })
end

return M
