-- Global Imports
local gls = require('galaxyline').section

-- Local Imports
local colors = require("plug.global_colors")

local utils = {} -- This gets exported

-- Cursor position helper
utils.cursor_position = function()
  local current_line = vim.fn.line('.')
  local current_col = vim.fn.virtcol('.')
  return current_line .. ':' .. current_col .. " "
end

-- Cursor position percentage through the given buffer
utils.cursor_position_perc = function()
  local current_line = vim.fn.line('.')
  local num_lines = vim.fn.line('$')
  local sep = " | "
  local whereami = ""

  if current_line == 1 then
    whereami = 'Top '
  elseif current_line == num_lines then
    whereami = 'Bot '
  else
    local perc = math.floor(current_line / num_lines * 100)
    whereami = string.format("%2d",  perc) .. ' %'
  end

  return sep .. whereami
end

-- Map that convert mode identification (see `:help modes()`) to a name and color.
local mode_map = {
  ['n']  = {'',   colors.blue},
  ['i']  = {'INSERT',   colors.green},
  ['R']  = {'REPLACE',  colors.red},
  ['v']  = {'VISUAL',   colors.magenta},
  ['V']  = {'V-LINE',   colors.magenta},
  [''] = {'V-BLOCK',  colors.violet},
  ['s']  = {'SELECT',   colors.yellow},
  ['S']  = {'S-LINE',   colors.orange},
  [''] = {'S-BLOCK',  colors.red},
  ['c']  = {'COMMAND',  colors.orange},
  ['t']  = {'TERMINAL', colors.grey},
  ['Rv'] = {'VIRTUAL',  colors.red},
  ['rm'] = {'--MORE',   colors.cyan},
  -- Fallback mode.
  ['fallback'] = {'UNKNOWN', colors.blue}
}

-- Return the current mode name.
function utils.mode_name()
  local mode = mode_map[vim.fn.mode()]
  local str = ""

  -- Fallback if a mode is not available in `mode_map`.
  if mode == nil then
    str = mode_map['n'][1]
  else
    str = mode[1]
  end

  -- Make the string size constant.
  local mode_len = string.len(str)
  local delta = math.floor((8 - mode_len)/2)
  local str = string.rep(" ", delta) .. str .. string.rep(" ", 8 - mode_len - delta)
  return str
end

-- Return the highlight color of the current mode.
function utils.mode_hl()
  local mode = mode_map[vim.fn.mode()]

  -- Fallback color is a mode is not available in `mode_map`.
  if mode == nil then
    mode = mode_map['n']
    return mode[2]
  end
  return mode[2]
end

-- Inserts the given component table into the RIGHT galaxyline section.
-- Components get inserted one after another, so order matters.
function utils.ins_right(component)
    table.insert(gls.right, component)
end

-- Inserts the given component table into the LEFT galaxyline section.
-- Components get inserted one after another, so order matters.
function utils.ins_left(component)
    table.insert(gls.left, component)
end

-- Inserts the given component table into the MID galaxyline section.
-- Components get inserted one after another, so order matters.
function utils.ins_mid(component)
    table.insert(gls.mid, component)
end

-- Inserts the given component table into the SHORT_LINE_LEFT galaxyline section.
-- Components get inserted one after another, so order matters.
function utils.ins_short_left(component)
    table.insert(gls.short_line_left, component)
end

-- Inserts the given component table into the SHORT_LINE_RIGHT galaxyline section.
-- Components get inserted one after another, so order matters.
function utils.ins_short_right(component)
    table.insert(gls.short_line_right, component)
end

-- Return our utilities
return utils