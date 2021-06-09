-- Global Imports
local gl = require("galaxyline")
local condition = require("galaxyline.condition")

-- Local Imports
local utils = require("utils")
local colors = require("colors")
local ins_short_left = utils.ins_short_left
local ins_short_right = utils.ins_short_right

gl.short_line_list = {'NvimTree', 'vista', 'dbui', 'packer'}

ins_short_left {
  ShortLineSeparator = {
    provider = function() return ' ' end,
    highlight = {colors.section_bg, colors.section_bg},
  }
}

ins_short_left {
    FileIcon = {
        provider = {function() return '  ' end, 'FileIcon'},
        condition = condition.buffer_not_empty,
        highlight = {
          require('galaxyline.provider_fileinfo').get_file_icon,
          colors.section_bg
        }
    }
}

ins_short_left {
  ShortLineFileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
    highlight = {colors.fg, colors.section_bg},
    separator = '',
    separator_highlight = {colors.section_bg, colors.bg}
  },
}

-- Buffer icon
-- -----------

ins_short_right {
  BufferIcon = {
    provider = 'BufferIcon',
    highlight = {colors.fg, colors.bg}
  }
}