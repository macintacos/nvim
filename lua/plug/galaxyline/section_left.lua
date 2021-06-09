-- Global imports
local condition = require('galaxyline.condition')

-- Local imports
local utils = require("utils")
local mode_name = utils.mode_name
local mode_hl = utils.mode_hl
local ins_left = utils.ins_left
local colors = require("plug.global_colors")

ins_left {
    ViMode = {
        provider = function()
            vim.api.nvim_command('hi GalaxyViMode guifg=' .. mode_hl())
            return '█' .. ' '
        end,
        highlight = {colors.fg, colors.section_bg}
    }
}

-- Show something if we're recording
ins_left {
    Macro = {
        provider = function()
            local reg = vim.fn.reg_recording()

            if (reg == nil) or (reg == '') then
                return ''
            else
                return '   ' .. vim.call('reg_recording')
            end
        end,
        highlight = {colors.red, colors.section_bg}
    }
}

ins_left {
    FileIcon = {
        provider = {function() return '  ' end, 'FileIcon'},
        condition = condition.buffer_not_empty,
        highlight = {
          require('galaxyline.provider_fileinfo').get_file_icon,
          colors.section_bg
        }
    }
}

ins_left {
    FileName = {
        provider = 'FileName',
        condition = condition.buffer_not_empty,
        highlight = {colors.fg, colors.section_bg}
    }
}

ins_left {
    SectionSeparatorMarker = {
        provider = function() return '' end,
        highlight = {colors.section_bg, colors.bg}
    }
}

ins_left {
    SectionSeparator = {
        provider = function() return ' ' end,
        highlight = {colors.fg, colors.bg}
    }
}

-- GIT STUFF
ins_left {
    GitIcon = {
        provider = function() return ' ' end,
        condition = condition.check_git_workspace,
        highlight = {colors.orange, colors.bg},
        separator = ' ',
        separator_highlight = {colors.orange, colors.bg}
    }
}

ins_left {
    GitBranch = {
        provider = 'GitBranch',
        condition = condition.check_git_workspace,
        highlight = {colors.fg, colors.bg, 'bold'},
        separator = ' ',
        separator_highlight = {colors.orange, colors.bg}
    }
}

ins_left {
    DiffAdd = {
        provider = 'DiffAdd',
        condition = condition.hide_in_width,
        highlight = {colors.green, colors.bg},
        icon = '+'
    }
}

ins_left {
    DiffModified = {
        provider = 'DiffModified',
        condition = condition.hide_in_width,
        highlight = {colors.orange, colors.bg},
        icon = '~'
    }
}

ins_left {
    DiffRemove = {
        provider = 'DiffRemove',
        condition = condition.hide_in_width,
        highlight = {colors.red, colors.bg},
        icon = '-'
    }
}

-- LSP
ins_left {
    GetLspClient = {
        provider = {function()
            local status = vim.fn["coc#status"]()
            if status == "" then return "" end
            return " " .. status .. " "
        end},
        highlight = {colors.fg, colors.bg},
        separator = "",
        separator_highlight = {colors.bg, colors.section_bg}
    }
}
