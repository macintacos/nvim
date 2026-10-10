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

-- Neovim exposes no open fold's start outside C; snacks.statuscolumn reads it
-- the same way. pcall: another plugin may have declared these types already.
local ffi = require("ffi")
pcall(
  ffi.cdef,
  [[
  typedef struct {} Error;
  typedef struct {} win_T;
  typedef struct { int start; int level; int llevel; int lines; } foldinfo_T;
  foldinfo_T fold_info(win_T *wp, int lnum);
  win_T *find_window_by_handle(int window, Error *err);
]]
)

---The chevron 'fillchars' gives the fold starting at a line, or nil when none
---does. Blank 'foldsep' and 'foldinner' leave nothing else for `%C` to draw.
---@param lnum integer
---@return string?
local function chevron(lnum)
  local info = ffi.C.fold_info(ffi.C.find_window_by_handle(0, ffi.new("Error")), lnum)
  local fillchars = vim.opt.fillchars:get()
  if info.lines > 0 then
    return fillchars.foldclose
  end
  if info.level > 0 and info.start == lnum then
    return fillchars.foldopen
  end
end

---Fold slot for one row: changeset's review comment bubble on a line's first
---row when it has one, the chevron of a fold starting on the line, a blank
---otherwise. Drawn rather than left to `%C`, which paints FoldColumn alone and
---so stops changeset's added-line tint one cell short of the edge; a group named
---here only lays its colours over the row's number highlight.
---@param lnum integer Buffer line being drawn, 1-based (|v:lnum|).
---@param virtnum integer Index of this row within that line's rows (|v:virtnum|).
---@return string
function M.fold(lnum, virtnum)
  if virtnum ~= 0 then
    return " "
  end
  -- Requiring changeset here would load it at startup; until it loads, no line has a bubble.
  ---@type { bubble?: fun(buf: integer, lnum: integer): string?, string? }?
  local changeset = package.loaded.changeset
  local glyph, hl
  if changeset and changeset.bubble then
    glyph, hl = changeset.bubble(0, lnum)
  end
  glyph = glyph or chevron(lnum)
  return glyph and "%#" .. (hl or "FoldColumn") .. "#" .. glyph .. "%*" or " "
end

return M
