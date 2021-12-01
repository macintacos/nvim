local gps = require('nvim-gps')

require("lualine").setup {
    options = {
        theme = "dracula-nvim",
        disabled_filetypes = {'minimap'}
    },
    extensions = {
        "nvim-tree", "quickfix"
    },
    sections = {
        lualine_b = {},
        lualine_c = {'filetype', 'filename', {gps.get_location, cond = gps.is_available}},
        lualine_x = {},
        lualine_y = {
            {
                'diff',
                symbols = {
                    added = 'ﰂ ',
                    modified = ' ',
                    removed = 'ﯰ '
                }
            },
            'branch',
            {
                'diagnostics',
                sources = {'nvim_lsp'},
                symbols = {error = ' ', warn = ' ', info = ' ', hint = ' '}
            },
            'progress'
        },
    }
}
