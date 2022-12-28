--[[ TODOS

TODO: Pin versions for as many projects that support it.
TODO: For repositories that don't use release tagging with semver - open an issue in their repo to request that they add it (so that it works well with folke/lazy.nvim)

--]]


-- Top-level Imports

require("main.remap")
require("main.opts")
require("main.autocmds")

--[[

Plugin installation is handled here. Plugin-related configuration is located in after/plugins.

I'm doing this to keep things a little more centralized. I find myself jumping back and forth across different files whenever
I am messing with my configuration, which is less than ideal.

--]]

--[[ SETUP 'folke/lazy.nvim' ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none", "--single-branch",
        "https://github.com/folke/lazy.nvim.git", lazypath
    })
end
vim.opt.runtimepath:prepend(lazypath)

--[[ PLUGINS ]]
require("lazy").setup({
    -- Essential
    { "nvim-lua/plenary.nvim" },
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
    {
        'VonHeikemen/lsp-zero.nvim',
        dependencies = {
            -- LSP Support
            'neovim/nvim-lspconfig',
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'folke/neodev.nvim',

            -- Autocompletion
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-nvim-lua',

            -- Snippets
            'L3MON4D3/LuaSnip',
            'rafamadriz/friendly-snippets'
        }
    },
    { -- default picker UI for many, many things
        "nvim-telescope/telescope.nvim",
        version = "^0.1.0",
        dependencies = { "nvim-lua/popup.nvim" },
    },
    { "nvim-telescope/telescope-github.nvim" }, -- integration with the GitHub CLI
    { "nvim-telescope/telescope-file-browser.nvim" }, -- file browser in telescope
    { "crispgm/telescope-heading.nvim" }, -- add ability to navigate by headers in a Markdown/RST document
    { "dhruvmanila/telescope-bookmarks.nvim" }, -- add ability to jump to bookmarks using Telescope
    { "jvgrootveld/telescope-zoxide" }, -- integrate zoxide into the Telescope picker
    { "nvim-telescope/telescope-project.nvim" }, -- project management
    {
        'nvim-telescope/telescope-fzf-native.nvim', -- use fzf as the sorting algorithm for telescope
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build'
    },

    -- Appearance Plugins
    { "kyazdani42/nvim-web-devicons" },
    { "nvim-lualine/lualine.nvim" },
    { "nyoom-engineering/oxocarbon.nvim" }, -- theme
    { "challenger-deep-theme/vim" }, -- theme
    { "onsails/lspkind-nvim" }, -- adds icons to autocomplete menu
    { "Mofiqul/trld.nvim" }, -- show diagnostic info @ top-left
    { "b0o/incline.nvim" },
    { "lukas-reineke/indent-blankline.nvim" },
    { "petertriho/nvim-scrollbar", config = function() require("scrollbar").setup() end },
    { "folke/noice.nvim", version = "^1.0.0" }, -- adds a bunch of new UI elements
    { "stevearc/dressing.nvim" },

    -- Utilities
    { "stevearc/aerial.nvim" },
    { "folke/which-key.nvim" },
    { "tpope/vim-surround" },
    { "tpope/vim-repeat" },
    { "folke/trouble.nvim" },
    { "windwp/nvim-autopairs" }, -- auto-close pairs, also handles small text insertions
    { "monaqa/dial.nvim" }, -- better '<C-a>'/etc. bindings
    { "dhruvasagar/vim-prosession", dependencies = { "tpope/vim-obsession" } },
    { "akinsho/bufferline.nvim", version = "^3.0.0" },
    {
        "mrjones2014/legendary.nvim",
        version = "^2.1.0",
        config = function() require("legendary").setup() end
    }, -- a picker for finding commands defined in the environment
    { "ggandor/leap.nvim", config = function() require('leap').set_default_keymaps() end }, -- a way to navigate your code better
    { "ggandor/flit.nvim", config = function() require("flit").setup() end }, -- enhanced f/F/t/T motions, built on leap.nvim
    {
        "nvim-neo-tree/neo-tree.nvim",
        version = "^2.0.0",
        dependencies = {
            "MunifTanjim/nui.nvim",
            {
                -- Allows use of the commands with "_with_window_picker" suffix
                's1n7ax/nvim-window-picker',
                version = "^1.0.0",
                config = function()
                    require 'window-picker'.setup({
                        autoselect_one = true,
                        include_current = false,
                        filter_rules = {
                            -- filter using buffer options
                            bo = {
                                -- if the file type is one of following, the window will be ignored
                                filetype = {
                                    'neo-tree', "neo-tree-popup", "notify"
                                },

                                -- if the buffer type is one of following, the window will be ignored
                                buftype = { 'terminal', "quickfix" }
                            }
                        },
                        other_win_hl_color = '#e35e4f'
                    })
                end
            }
        }
    },
}, {
    checker = {
        enabled = true,
        notify = false,
    }
})
