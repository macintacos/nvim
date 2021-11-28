local actions = require("telescope.actions")

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
        file_ignore_patterns = {".git"},
        generic_sorter = require'telescope.sorters'.get_generic_fuzzy_sorter,
        find_command = {
            "rg", "--ignore", "--hidden", "--files", "--smartcase"
        },

        -- Appearance
        set_env = {['COLORTERM'] = 'truecolor'}, -- default = nil,
        sorting_strategy = "ascending",
        use_less = false,
        winblend = 0,
        prompt_prefix = "  ",
        selection_caret = " ",

        -- Mappings
        mappings = {
            i = {
                ["<C-n>"]   = false,
                ["<C-p>"]   = false,
                ["<C-j>"]   = actions.move_selection_next,
                ["<C-k>"]   = actions.move_selection_previous,
                ["<Tab>"]   = actions.move_selection_next,
                ["<S-Tab>"] = actions.move_selection_previous,
                ["K"]       = actions.toggle_selection + actions.move_selection_worse,
                ["J"]       = actions.toggle_selection + actions.move_selection_better,
            }
        },

        -- Previewers
        file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
        grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
        qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,

        -- Developer configurations: Not meant for general override
        buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker
    },
    pickers = {
        buffers                   = { theme = "ivy" },
        colorscheme               = { theme = "ivy" },
        current_buffer_fuzzy_find = { theme = "ivy" },
        file_browser              = { theme = "ivy" },
        find_files                = { theme = "ivy" },
        git_bcommits              = { theme = "ivy" },
        git_commits               = { theme = "ivy" },
        grep_string               = { theme = "ivy" },
        heading                   = { theme = "ivy" },
        help_tags                 = { theme = "ivy" },
        highlights                = { theme = "ivy" },
        keymaps                   = { theme = "ivy" },
        live_grep                 = { theme = "ivy" },
        lsp_document_symbols      = { theme = "ivy" },
        lsp_workspace_symbols     = { theme = "ivy" },
        man_pages                 = { theme = "ivy" },
        zoxide                    = { theme = "ivy" },
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

-- Extension Loading
require("telescope").load_extension("fzf")
require("telescope").load_extension("gh")
require("telescope").load_extension("bookmarks")
require("telescope").load_extension("heading")
require("telescope").load_extension("zoxide")
require("telescope").load_extension("project")

-- Zoxide-specific
require("telescope._extensions.zoxide.config").setup({
    mappings = {
        default = {
            action = function(selection)
                vim.cmd("cd " .. selection.path)
            end,
            after_action = function(selection)
                vim.cmd("Prosession .")
                print("Directory changed to " .. selection.path)
            end
        }
    }
})
