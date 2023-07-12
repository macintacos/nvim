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

    ---Libraries
    { "nvim-lua/plenary.nvim" }, -- library that basically all plugins seem to use for whatever reason

    ---Language Features
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" }, -- pretty/efficient highlighting
    { "NoahTheDuke/vim-just" },

    --[[ ESSENTIAL: END ]]

    --[[ APPEARANCE: START ]]

    ---Themes
    { "challenger-deep-theme/vim" },
    { "folke/tokyonight.nvim" },
    { "nyoom-engineering/oxocarbon.nvim" },
    { "Mofiqul/dracula.nvim" },
    { "EdenEast/nightfox.nvim" },
    { "Yazeed1s/minimal.nvim" },
    { "2nthony/vitesse.nvim" },

    ---Libraries (used by other plugins)
    { "MunifTanjim/nui.nvim" }, -- UI library, used in other plugins
    { "kyazdani42/nvim-web-devicons" }, -- adds icons to the neovim UI
    { "stevearc/dressing.nvim" }, -- UI library, used in other plugins

    ---Everything Else
    { "Mofiqul/trld.nvim" }, -- show diagnostic info @ top-left
    { "b0o/incline.nvim" }, -- adds the title of the file to the winbar
    { "folke/noice.nvim", version = "^1.0.0" }, -- adds a bunch of new UI elements
    { "folke/paint.nvim" }, -- define arbitrary highlights in the editor
    { "nvim-lualine/lualine.nvim" }, -- status line plugin
    { "levouh/tint.nvim" }, -- tinting windows other than the current buffer
    { "petertriho/nvim-scrollbar", config = true }, -- adds a scrollbar, similar to vscode
    { "lewis6991/gitsigns.nvim" }, -- git integration with the editor to provide better line-by-line info
    { "mvllow/modes.nvim" }, -- colors the cursor and highlights lines depending on mode you're in

    --[[ APPEARANCE: END ]]

    --[[ UTILITY: START]]
    ---Libraries
    { "inkarkat/vim-ingo-library" },
    { "romgrk/fzy-lua-native" }, -- fzf library for lua
    { "anuvyklack/middleclass" }, -- OOP library for lua

    ---Interactive UIs
    { "crispgm/telescope-heading.nvim" }, -- add ability to navigate by headers in a Markdown/RST document
    { "dhruvmanila/telescope-bookmarks.nvim" }, -- add ability to jump to bookmarks using Telescope
    { "folke/todo-comments.nvim" }, -- adds nicer TODO-style comment behavior
    { "folke/trouble.nvim" }, -- fancier quickfix
    { "folke/zen-mode.nvim", config = true }, -- focus on a single buffer
    { "ibhagwan/fzf-lua" }, -- fzf picker, for things where telescope falls down. Preferred.
    { "jvgrootveld/telescope-zoxide" }, -- integrate zoxide into the Telescope picker
    { "kdheepak/lazygit.nvim" }, -- lazygit in neovim
    { "kevinhwang91/nvim-bqf", ft = "qf", config = true }, -- enhancements to the quickfix menu
    { "mbbill/undotree" }, -- undo manager
    { "mrjones2014/legendary.nvim", version = "^2.1.0", config = true }, -- a picker for finding neovim commands
    { "nvim-treesitter/playground", build = ":TSInstall query" }, -- playground for treesitter, just because
    { "pwntester/octo.nvim" }, -- GitHub UI/command library
    { "nvim-colortils/colortils.nvim", config = true }, -- color GUI helper tool
    {
        -- picker UI for many, many things
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/popup.nvim" },
    },
    { "nvim-telescope/telescope-github.nvim" }, -- integration with the GitHub CLI
    { "nvim-telescope/telescope-file-browser.nvim" }, -- file browser in telescope
    {
        "nvim-telescope/telescope-fzf-native.nvim", -- use fzf as the sorting algorithm for telescope
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    },
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
    { "eraserhd/parinfer-rust", build = "cargo build --release" }, -- better parenthesis management
    { "folke/which-key.nvim" }, -- indispensible
    { "ggandor/flit.nvim", opts = { labeled_modes = "nv" } },
    { "inkarkat/vim-LineJuggler" }, -- duplicating lines and stuff like that
    { "mg979/vim-visual-multi", branch = "master" }, -- multiple cursors in neovim
    { "monaqa/dial.nvim" }, -- better '<C-a>'/etc. bindings
    { "numToStr/Comment.nvim", config = true }, -- code commenting plugin
    { "preservim/vim-textobj-sentence" }, -- text objects for sentences
    { "gbprod/yanky.nvim" }, -- better copying/pasting
    { "tpope/vim-repeat" }, -- repeat functionality integration for plugins
    { "kylechui/nvim-surround" }, -- indispensible text surrounding helper functions
    { "wellle/targets.vim" }, -- more text objects
    { "windwp/nvim-autopairs" }, -- auto-close pairs, also handles small text insertions
    { "gaoDean/autolist.nvim" }, -- list continuation stuff
    { "chrisgrieser/nvim-recorder" }, -- simplify using macros
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        ---@type Flash.Config
        opts = {},
        keys = {
            {
                "s",
                mode = { "n", "x", "o" },
                function()
                    -- default options: exact mode, multi window, all directions, with a backdrop
                    require("flash").jump()
                end,
            },
            {
                "S",
                mode = { "n", "o", "x" },
                function()
                    require("flash").treesitter()
                end,
            },
        },
    },

    ---Enhanced Editor Behavior
    { "RRethy/vim-illuminate" }, -- highlight words under the cursor
    { "tpope/vim-sensible" }, -- sensible vim defaults
    { "dhruvasagar/vim-prosession", dependencies = { "tpope/vim-obsession" } }, -- better session management
    { "echasnovski/mini.nvim" }, -- library of interesting modules for better editor behavior
    {
        "iamcco/markdown-preview.nvim", -- markdown previews
        build = function()
            vim.fn["mkdp#util#install"]()
        end,
    },
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
    { "SidOfc/mkdx" }, -- markdown helper stuff
    { "anuvyklack/fold-preview.nvim" }, -- shows previews of folds
    { "anuvyklack/keymap-amend.nvim" }, -- keymaps for previews of folds
    { "NvChad/nvim-colorizer.lua" }, -- shows colors for valid sequences in open buffers
    { "HiPhish/nvim-ts-rainbow2" }, -- rainbow colors with treesitter
    { "anuvyklack/windows.nvim", config = true }, -- helps resize windows automatically
    { "mong8se/actually.nvim" }, -- helps you open the files you meant to open

    --[[ UTILITY: END ]]
}, lazy_options)
