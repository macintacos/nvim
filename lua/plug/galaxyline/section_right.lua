-- Local Imports
local colors = require("plug.global_colors")
local utils = require("utils")
local cursor_position = utils.cursor_position
local cursor_position_perc = utils.cursor_position_perc
local mode_hl = utils.mode_hl
local ins_right = utils.ins_right

ins_right {
  CursorPosition = {
    provider = {
      cursor_position
    },
    highlight = {colors.fg, colors.section_bg},
  }
}

ins_right {
  FileSize = {
    condition = function()
      return require('galaxyline.provider_fileinfo').get_file_size() ~= ''
    end,
    provider = {function() return ' ' end, 'FileSize'},
    highlight = {colors.fg, colors.section_bg},
    separator = ' |',
    separator_highlight = {colors.fg, colors.section_bg}
  }
}

ins_right {
  CursorPerc = {
    provider = {
      cursor_position_perc,
      function() return ' ' end
    },
    highlight = {colors.fg, colors.section_bg},
  }
}

ins_right {
  ViModeRight = {
    provider = function()
    --   vim.api.nvim_command('hi GalaxyViMode guifg=' .. mode_hl())
      return '█'
    end,
    highlight = {mode_hl(), colors.bg},
    separator = '',
    separator_highlight = {colors.section_bg, mode_hl()}
  }
}
