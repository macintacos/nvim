local M = {}

-- Box-drawing strokes are centered in their cell, so a run of them lines up
-- under the line number's digits. Arrows like `↳` hang their stem off the left
-- edge of the cell instead, which reads as off-centre next to a number.
local STEM = "│"
local ELBOW = "╰"

---Line number for one row of buffer text, right-aligned in a field as wide as
---Vim sizes its own number column: 'numberwidth', grown to fit the buffer's
---highest line number. `%l` emits bare digits and leaves placement to `%=`, so
---nothing reserves that room and a long number crowds the fold column to its
---left. A fixed field keeps every row's layout still.
---@param lnum integer Buffer line being drawn, 1-based (|v:lnum|).
---@param relnum integer Its distance from the cursor line (|v:relnum|).
---@return string
function M.line_number(lnum, relnum)
  local number = (vim.wo.relativenumber and relnum ~= 0) and relnum or lnum
  local width = math.max(vim.wo.numberwidth, #tostring(vim.api.nvim_buf_line_count(0)) + 1)
  return string.format("%" .. width .. "d", number)
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

return M
