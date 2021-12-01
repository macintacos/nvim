require("bufferline").setup {
    options = {
        numbers = "ordinal",
        close_command = "BDelete this",
        offsets = {
            {
                filetype = "NvimTree",
                text = function()
                    local cwd = vim.fn.getcwd()
                    local name = vim.api.nvim_call_function('fnamemodify', {cwd, ':t'})
                    return " "..name
                end,
                highlight = "Directory",
                text_align = "left"
            }
        }
    }
}

-- Appearance
local colors = require("plugin.global_colors")
local api = vim.api
local hi = api.nvim_set_hl
local ns = api.nvim_create_namespace("macintacos")

hi(ns, "BufferLineSeparator", {fg = colors.background_light})

