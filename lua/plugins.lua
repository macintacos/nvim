---@diagnostic disable: undefined-global
local install_path = vim.fn.stdpath("data") ..
                         "/site/pack/packer/start/packer.nvim"

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.api.nvim_command(
        "!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
    vim.api.nvim_command "packadd packer.nvim"
end

-- Compile when there are changes to this file
vim.cmd "autocmd BufWritePost plugins.lua PackerCompile"

-- Because: https://github.com/wbthomason/packer.nvim/issues/202
require("packer").init({max_jobs = 50})

-- Plugins specified here!
return require("packer").startup(function(use)
    -- Get Packer to manage itself
    use {"wbthomason/packer.nvim", config = {
        profile = {
            enable = true,
            threshold = 1
        }
    }}

    -- Essential
    -- TODO: For all Telescope stuff, need to make keymaps
    -- TODO: Consider using snap? https://github.com/camspiers/snap
    -- Make sure to look at all of the available pickers: https://github.com/nvim-telescope/telescope.nvim#pickers
    use {
        "nvim-telescope/telescope.nvim",
        requires = {{"nvim-lua/plenary.nvim"}, {"nvim-lua/popup.nvim"}}
    }
    use {"nvim-telescope/telescope-fzf-native.nvim", run = "make"}
    use {"nvim-telescope/telescope-github.nvim"}
    use {"nvim-telescope/telescope-project.nvim"}
    use {"crispgm/telescope-heading.nvim"}
    use {"dhruvmanila/telescope-bookmarks.nvim"}
    use {"jvgrootveld/telescope-zoxide"}
    use {"tpope/vim-sensible"}

    -- Language Features
    use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}
    use {"kkoomen/vim-doge", run = ":call doge#install()"}
    use {"preservim/vim-lexical"}
    use {"preservim/vim-pencil"}

    -- Language
    use {"fatih/vim-go", run = ":GoUpdateBinaries"}
    use {"MTDL9/vim-log-highlighting"}
    use {"SidOfc/mkdx"}
    use {"iamcco/markdown-preview.nvim", run = "cd app && yarn install"}

    -- Appearance
    use {"kyazdani42/nvim-web-devicons"}
    use {"norcalli/nvim-colorizer.lua"}
    use {"lukas-reineke/indent-blankline.nvim" } -- TODO: make a different highlight for Python, similar to indent rainbow?
    -- use {"romgrk/barbar.nvim"}
    use {'akinsho/bufferline.nvim', requires = 'kyazdani42/nvim-web-devicons'}
    use {"kyazdani42/nvim-tree.lua", requires = "kyazdani42/nvim-web-devicons"}
    use {"nvim-lualine/lualine.nvim", requires = {"kyazdani42/nvim-web-devicons", opt = true}}
    use {"Mofiqul/dracula.nvim"}

    -- Utilities
    use {"TimUntersberger/neogit", requires = "nvim-lua/plenary.nvim"}
    use {"pwntester/octo.nvim"}
    use {"stevearc/stickybuf.nvim"}
    use {"folke/which-key.nvim"}
    use {"airblade/vim-rooter"}
    use {"dhruvasagar/vim-prosession", requires = {"tpope/vim-obsession"}}
    use {"kevinhwang91/nvim-hlslens"}
    use {"nacro90/numb.nvim"}
    use {"folke/trouble.nvim"}
    use {"arthurxavierx/vim-caser"}
    use {"kazhala/close-buffers.nvim"}
    use {
        "folke/zen-mode.nvim",
        config = function() require("zen-mode").setup {} end
    }
    use {"sudormrfbin/cheatsheet.nvim"}
    use {"tpope/vim-repeat"}
    use {"mtth/scratch.vim"}
    use {"t9md/vim-choosewin"}
    use {"troydm/zoomwintab.vim"}
    use {"psliwka/vim-smoothie"}
    use {"jeffkreeftmeijer/vim-numbertoggle"}
    use {"folke/todo-comments.nvim"}
    use {"dstein64/vim-startuptime"}
    use {"marklcrns/vim-smartq"}
    use {"fedepujol/move.nvim"}
    use {"inkarkat/vim-visualrepeat", requires = {"inkarkat/vim-ingo-library"}}
    use {"justinmk/vim-gtfo"}

    -- Text Manipulation
    use {"ervandew/supertab"}
    use {"tpope/vim-endwise"}
    use {"numToStr/Comment.nvim"}
    use {"tpope/vim-eunuch"}
    use {"windwp/nvim-spectre"}
    use {"windwp/nvim-autopairs"}
    use {"mizlan/iswap.nvim", config = function() require("iswap").setup {} end}
    use {"tpope/vim-surround"}
    use {"junegunn/vim-easy-align"}
    use {"AndrewRadev/splitjoin.vim"}
    use {"andymass/vim-matchup"}
    use {"mg979/vim-visual-multi", branch = "master"}
    use {"ggandor/lightspeed.nvim"}
    use {"svermeulen/vim-cutlass"}
    use {"svermeulen/vim-yoink"}
    use {"itchyny/vim-cursorword"}
    use {"inkarkat/vim-LineJuggler"}
    use {"ntpeters/vim-better-whitespace"}
    use {"wellle/targets.vim"}
    use {"kana/vim-textobj-user"}
    use {"preservim/vim-textobj-quote"}
    use {"preservim/vim-textobj-sentence"}
    use {"gelguy/wilder.nvim", requires = {"romgrk/fzy-lua-native", run = "make"}}

    -- Git
    use {"lewis6991/gitsigns.nvim"}
    use {"tpope/vim-fugitive"}
end)
