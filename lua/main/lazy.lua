--[[

Plugin installation is handled here. Plugin-related configuration is located in after/plugins.

I'm doing this to keep things a little more centralized. I find myself jumping back and forth across different files whenever
I am messing with my configuration, which is less than ideal.

TODOs

TODO: Command all plugins with a small description about what they are for.
TODO: For hlslens, check on the other plugin integrations in the README.

--]]

--[[ lazy.nvim's options ]]
local lazy_options = {
    checker = {
        enabled = true,
        notify = false,
    },
}

--[[ SETUP 'folke/lazy.nvim' ]]
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--single-branch",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.runtimepath:prepend(lazypath)

--[[ PLUGINS ]]
require("lazy").setup({

    --[[ ESSENTIAL: START ]]

    { "nvim-lua/plenary.nvim" }, -- library that basically all plugins seem to use for whatever reason
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" }, -- pretty/efficient highlighting
    {
        "VonHeikemen/lsp-zero.nvim", -- configure LSPs for me. I hate that this isn't default behavior, but here we are.
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" }, -- LSP configuration repository
            { "williamboman/mason.nvim" }, -- A kind-of package manager for LSPs/DAPs/Linters/etc.
            { "williamboman/mason-lspconfig.nvim" }, -- bridge for mason and lspconfig

            -- Autocompletion
            { "hrsh7th/nvim-cmp" }, -- handles completion
            { "hrsh7th/cmp-buffer" }, -- gathers potential completion results from the buffer
            { "hrsh7th/cmp-path" }, -- gathers potential completion results from paths
            { "saadparwaiz1/cmp_luasnip" }, -- gathers potential completion results from luasnip snippets
            { "hrsh7th/cmp-nvim-lsp" }, -- gathers potential completion results from the LSP
            { "hrsh7th/cmp-nvim-lua" }, -- gathers potential completion results from lua
            { "ray-x/cmp-treesitter" }, -- gathers potential completion results from treesitter
            { "mtoohey31/cmp-fish", ft = "fish" }, -- gathers potential completion results for fish files

            -- Snippets
            { "L3MON4D3/LuaSnip" }, -- snippet manager
            { "rafamadriz/friendly-snippets" }, -- another snipper manager
        },
    },
    { "folke/neodev.nvim" }, -- makes building your own config/lua plugins significantly easier
    { "jose-elias-alvarez/null-ls.nvim" }, -- used for managing linters/formatters/etc. in lieu of direct Mason config
    { "jayp0521/mason-null-ls.nvim" }, -- bridge for mason to null-ls
    { "ibhagwan/fzf-lua" }, -- fzf picker, for things where telescope falls down
    { -- default picker UI for many, many things
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/popup.nvim" },
    },
    { "nvim-telescope/telescope-github.nvim" }, -- integration with the GitHub CLI
    { "nvim-telescope/telescope-file-browser.nvim" }, -- file browser in telescope
    { "crispgm/telescope-heading.nvim" }, -- add ability to navigate by headers in a Markdown/RST document
    { "dhruvmanila/telescope-bookmarks.nvim" }, -- add ability to jump to bookmarks using Telescope
    { "jvgrootveld/telescope-zoxide" }, -- integrate zoxide into the Telescope picker
    { "nvim-telescope/telescope-project.nvim" }, -- project management
    {
        "nvim-telescope/telescope-fzf-native.nvim", -- use fzf as the sorting algorithm for telescope
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    },
    { "tpope/vim-sensible" }, -- sensible vim defaults

    --[[ ESSENTIAL: END ]]

    --[[ APPEARANCE: START ]]

    ---Themes
    { "challenger-deep-theme/vim" },
    { "folke/tokyonight.nvim" },
    { "nyoom-engineering/oxocarbon.nvim" },
    { "Mofiqul/dracula.nvim" },
    { "EdenEast/nightfox.nvim" },

    ---Libraries (used by other plugins)
    { "MunifTanjim/nui.nvim" }, -- UI library, used in other plugins
    { "kyazdani42/nvim-web-devicons" }, -- adds icons to the neovim UI
    { "onsails/lspkind-nvim" }, -- adds icons to autocomplete menu
    { "stevearc/dressing.nvim" }, -- UI library, used in other plugins

    ---Everything Else
    { "Mofiqul/trld.nvim" }, -- show diagnostic info @ top-left
    { "b0o/incline.nvim" }, -- adds the title of the file to the winbar
    { "folke/lsp-colors.nvim", config = true }, -- adds some missing highlight groups for LSP diagnostics
    { "folke/noice.nvim", version = "^1.0.0" }, -- adds a bunch of new UI elements
    { "folke/paint.nvim" }, -- define arbitrary highlights in the editor
    { "j-hui/fidget.nvim", config = true }, -- adds loading indicators for LSP
    { "nvim-lualine/lualine.nvim" }, -- status line plugin
    { "levouh/tint.nvim" }, -- tinting windows other than the current buffer
    { "petertriho/nvim-scrollbar", config = true }, -- adds a scrollbar, similar to vscode
    -- { "rcarriga/nvim-notify" }, -- adds decent-looking notification banners for common operations
    { "lewis6991/gitsigns.nvim" }, -- git integration with the editor to provide better line-by-line info

    --[[ APPEARANCE: END ]]

    --[[ UTILITY: START]]
    ---Libraries
    { "inkarkat/vim-ingo-library" },
    { "romgrk/fzy-lua-native" }, -- fzf library for lua

    ---Interactive UIs
    -- { "akinsho/bufferline.nvim", version = "^3.0.0" }, -- a nice bufferline
    { "noib3/nvim-cokeline" }, -- a nice bufferline
    { "folke/todo-comments.nvim" }, -- adds nicer TODO-style comment behavior
    { "folke/trouble.nvim" }, -- fancier quickfix
    { "folke/zen-mode.nvim", config = true }, -- focus on a single buffer
    { "kdheepak/lazygit.nvim" }, -- lazygit in neovim
    { "kevinhwang91/nvim-bqf", ft = "qf", config = true }, -- enhancements to the quickfix menu
    { "mbbill/undotree" }, -- undo manager
    { "mrjones2014/legendary.nvim", version = "^2.1.0", config = true }, -- a picker for finding neovim commands
    { "nvim-treesitter/playground", build = ":TSInstall query" }, -- playground for treesitter, just because
    { "pwntester/octo.nvim" }, -- GitHub UI/command library
    { "simrat39/symbols-outline.nvim", config = true }, -- outline for symbols
    {
        "nvim-neo-tree/neo-tree.nvim",
        version = "^2.0.0",
        dependencies = {
            {
                -- Allows use of the commands with "_with_window_picker" suffix
                "s1n7ax/nvim-window-picker",
                version = "^1.0.0",
            },
        },
    },

    ---Navigation/Text Manipulation
    { "andymass/vim-matchup" }, -- better %
    { "anuvyklack/hydra.nvim" }, -- hydra, but for neovim!
    { "arthurxavierx/vim-caser" }, -- add commands to change case of things
    { "fedepujol/move.nvim" }, -- moving lines/blocks of code around
    { "folke/which-key.nvim" }, -- indispensible
    { "ggandor/flit.nvim", config = { labeled_modes = "nv" } },
    { "ggandor/leap.nvim", config = function() require("leap").add_default_mappings() end }, -- code navigation
    { "inkarkat/vim-LineJuggler" }, -- duplicating lines and stuff like that
    { "mg979/vim-visual-multi", branch = "master" }, -- multiple cursors in neovim
    { "monaqa/dial.nvim" }, -- better '<C-a>'/etc. bindings
    { "numToStr/Comment.nvim", config = true }, -- code commenting plugin
    { "preservim/vim-textobj-sentence" }, -- text objects for sentences
    { "ray-x/lsp_signature.nvim", config = true }, -- nicer signatures when writing code
    { "gbprod/yanky.nvim" }, -- better copying/pasting
    { "tpope/vim-repeat" }, -- repeat functionality integration for plugins
    { "tpope/vim-surround" }, -- indispensible text surrounding helper functions
    { "wellle/targets.vim" }, -- more text objects
    { "windwp/nvim-autopairs" }, -- auto-close pairs, also handles small text insertions
    { "RRethy/vim-illuminate" }, -- highlight words under the cursor

    ---Enhanced Editor Behavior
    { "dhruvasagar/vim-prosession", dependencies = { "tpope/vim-obsession" } }, -- better session management
    { "echasnovski/mini.nvim", branch = "stable" }, -- library of interesting modules for better editor behavior
    { "iamcco/markdown-preview.nvim", build = function() vim.fn["mkdp#util#install"]() end }, -- markdown previews
    { "jeffkreeftmeijer/vim-numbertoggle" }, -- change line numbers for unfocused buffers
    { "justinmk/vim-gtfo" }, -- commands that let you invoke other applications
    { "kazhala/close-buffers.nvim", config = true }, -- mo' better buffer deletion
    { "kevinhwang91/nvim-hlslens" }, -- better highlighting when searching
    { "luukvbaal/stabilize.nvim", config = true }, -- predictable split creation. TODO: Remove when neovim 0.9.0 is released (ref: https://github.com/neovim/neovim/pull/19243)
    { "marklcrns/vim-smartq" }, -- 'q' now does better things
    { "nacro90/numb.nvim", config = true }, -- peek line numbers when using ":#"
    { "ojroques/nvim-bufdel" }, -- better buffer deletion
    { "rhysd/committia.vim" }, -- better commit interface
    { "smjonas/inc-rename.nvim", config = true },
    { "stevearc/stickybuf.nvim" }, -- makes it so that certain filetypes don't accidentally buffers stuffed in them
    { "tpope/vim-eunuch" }, -- access common shell commands
    { "tpope/vim-fugitive" }, -- git functionality basically everywhere
    { "SidOfc/mkdx" },

    --[[ UTILITY: END ]]
}, lazy_options)
