local M = {}

-- Box-drawing strokes are centered in their cell, so a run of them lines up
-- under the line number's digits. Arrows like `↳` hang their stem off the left
-- edge of the cell instead, which reads as off-centre next to a number.
local STEM = "│"
local ELBOW = "╰"

-- Cells plugin/mini/statuscolumn.lua draws beyond the fold, sign and number
-- columns Neovim reserves: the space ahead of the signs, and the separator.
local EXTRA = 2

---Line number for one row of buffer text, right-aligned in a fixed field:
---'numberwidth' less the cells the column adds elsewhere, so that the whole
---column is as wide as Neovim measures it. `%l` emits bare digits and leaves
---placement to `%=`, so nothing reserves that room and a long number crowds the
---fold column to its left. A fixed field keeps every row's layout still.
---@param lnum integer Buffer line being drawn, 1-based (|v:lnum|).
---@param relnum integer Its distance from the cursor line (|v:relnum|).
---@return string
function M.line_number(lnum, relnum)
  local number = (vim.wo.relativenumber and relnum ~= 0) and relnum or lnum
  local width = math.max(vim.wo.numberwidth - EXTRA, #tostring(vim.api.nvim_buf_line_count(0)) + 1)
  return string.format("%" .. width .. "d", number)
end

---'numberwidth' that fits a buffer's line numbers in line_number's field.
---
---Neovim measures a 'statuscolumn' as 'numberwidth' plus the fold and sign
---columns each time a buffer's line or sign count changes, and only widens it to
---what it draws once drawing starts. gitsigns lays out its inline deleted lines
---against that first measure, so any shortfall shows as those lines jumping
---sideways for a frame.
---@param line_count integer
---@return integer
function M.numberwidth(line_count)
  return #tostring(line_count) + 1 + EXTRA
end

---Marker for one soft-wrapped row, drawn so that the wrapped rows of a line
---form a single run descending from the line number and ending in an elbow.
---@param lnum integer Buffer line being drawn, 1-based (|v:lnum|).
---@param virtnum integer Index of this row within that line's wrapped rows (|v:virtnum|).
---@return string
function M.wrap_mark(lnum, virtnum)
  local height = vim.api.nvim_win_text_height(0, { start_row = lnum - 1, end_row = lnum - 1 })
  -- `fill` counts the line's virtual and diff-filler rows, which are drawn by
  -- their own rule and so are not part of the run.
  return virtnum == (height.all - height.fill - 1) and ELBOW or STEM
end

---Fold slot for one row: changeset's review comment bubble on a line's first
---row when it has one, the fold marker otherwise.
---@param lnum integer Buffer line being drawn, 1-based (|v:lnum|).
---@param virtnum integer Index of this row within that line's rows (|v:virtnum|).
---@return string
function M.fold(lnum, virtnum)
  -- Requiring changeset here would load it at startup; until it loads, no line has a bubble.
  local changeset = package.loaded.changeset
  local glyph, hl
  if changeset and changeset.bubble and virtnum == 0 then
    glyph, hl = changeset.bubble(0, lnum)
  end
  return glyph and "%#" .. hl .. "#" .. glyph .. "%*" or "%C"
end

return M
