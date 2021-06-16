local actions = require("telescope.actions")
local hi = vim.highlight.create
local colors = require("plug.global_colors")

-- api.nvim_set_hl_ns(ns)

require("telescope").setup {
    defaults = {
        -- General Config
        vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case', '--hidden'
        },
        initial_mode = "insert",
        selection_strategy = "reset",
        file_sorter = require'telescope.sorters'.get_fuzzy_file,
        file_ignore_patterns = {},
        generic_sorter = require'telescope.sorters'.get_generic_fuzzy_sorter,
        shorten_path = true,
        find_command = {
            "rg", "--ignore", "--hidden", "--files", "--smartcase"
        },

        -- Appearance
        border = {},
        borderchars = {'─', '│', '─', '│', '╭', '╮', '╯', '╰'},
        color_devicons = true,
        entry_prefix = "  ",
        layout_defaults = {
            horizontal = {mirror = false},
            vertical = {
                mirror = true,
                preview_height = 0.7
            }
        },
        layout_strategy = "vertical",
        preview_cutoff = 120,
        prompt_position = "top",
        prompt_prefix = "   ",
        results_height = 1,
        results_width = 0.8,
        selection_caret = "-> ",
        set_env = {['COLORTERM'] = 'truecolor'}, -- default = nil,
        sorting_strategy = "ascending",
        use_less = false,
        width = 0.75,
        winblend = 0,

        -- Mappings
        mappings = {
            i = {
                ["<C-n>"] = false,
                ["<C-p>"] = false,
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous
            }
        },

        -- Previewers
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
                }
            }
        }
    }
}

-- Appearance
hi("TelescopeNormal", {guibg = "#212337"}, false)
hi("TelescopeSelection", {guibg = "#313452", guifg=colors.green}, false)
hi("TelescopeMatching", {guifg = colors.orange}, false)
hi("TelescopePreviewMatch", {guifg = colors.orange}, false)

-- Extension Loading
require("telescope").load_extension("fzf")
require("telescope").load_extension("gh")
require("telescope").load_extension("zoxide")
require("telescope").load_extension("bookmarks")
require("telescope").load_extension("heading")
