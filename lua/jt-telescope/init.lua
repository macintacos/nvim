require("telescope").setup {
    defaults = {
        vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case'
        },
        prompt_position = "top",
        prompt_prefix = "> ",
        selection_caret = "> ",
        entry_prefix = "  ",
        initial_mode = "insert",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_strategy = "vertical",
        layout_defaults = {
            horizontal = {mirror = false},
            vertical = {mirror = true}
        },
        file_sorter = require'telescope.sorters'.get_fuzzy_file,
        file_ignore_patterns = {},
        generic_sorter = require'telescope.sorters'.get_generic_fuzzy_sorter,
        shorten_path = true,
        winblend = 0,
        width = 0.75,
        preview_cutoff = 120,
        results_height = 0.8,
        results_width = 0.8,
        border = {},
        borderchars = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'},
        color_devicons = true,
        use_less = true,
        set_env = {['COLORTERM'] = 'truecolor'}, -- default = nil,
        file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
        grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
        qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,

        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = false,
            override_file_sorter = true,
            case_mode = "smart_case"
        },
        bookmarks = {
            selected_browser = "google_chrome",
            url_open_command = "open",
            bookmarks = require('telescope.themes').get_dropdown {
                width = 0.8,
                results_height = 0.8,
                sorting_strategy = "descending",
                layout_defaults = {
                    horizontal = {mirror = false},
                    vertical = {mirror = false}
                },
            }
        }
    }
}

-- Extension Loading
require("telescope").load_extension("fzf")
require("telescope").load_extension("gh")
require("telescope").load_extension("zoxide")
require("telescope").load_extension("bookmarks")
require("telescope").load_extension("heading")
require("telescope").load_extension("frecency")

-- Extended Extension Settings
-- TODO: This should actually be how the command is shown, so you'd have to set this in the command/mapping itself
-- require('telescope').extensions.bookmarks.bookmarks(
--     require('telescope.themes').get_dropdown {
--         width = 0.8,
--         results_height = 0.8,
--         previewer = false
--     }
-- )
