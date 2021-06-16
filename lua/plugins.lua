---@diagnostic disable: undefined-global
-- Bootstrap packer
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
    -- TODO: Look into theming the highlight groups: https://github.com/nvim-telescope/telescope.nvim#how-to-change-telescope-highlights-group
    -- TODO: For all Telescope stuff, need to make keymaps
    -- Make sure to look at all of the available pickers: https://github.com/nvim-telescope/telescope.nvim#pickers
    use {
        "nvim-telescope/telescope.nvim",
        requires = {{"nvim-lua/plenary.nvim"}, {"nvim-lua/popup.nvim"}}
    }
    use {"nvim-telescope/telescope-fzf-native.nvim", run = "make"}
    use {"crispgm/telescope-heading.nvim"}
    use {"dhruvmanila/telescope-bookmarks.nvim"}
    use {"jvgrootveld/telescope-zoxide"}
    use {"nvim-telescope/telescope-github.nvim"}
    use {"tpope/vim-sensible"}
    use {"junegunn/fzf", run = function()
        vim.fn["fzf#install"]()
    end}
    use {"junegunn/fzf.vim"}

    -- Language Features
    use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}
    use {"neoclide/coc.nvim", branch = "release"}
    use {"kkoomen/vim-doge", run = ":call doge#install()"}
    use {"ludovicchabant/vim-gutentags"}
    use {"dense-analysis/ale"}
    use {"preservim/vim-lexical"}
    use {"preservim/vim-pencil"}

    -- Language specific
    use {"fatih/vim-go", run = ":GoUpdateBinaries"}
    use {"MTDL9/vim-log-highlighting"}
    use {"SidOfc/mkdx"}
    use {"iamcco/markdown-preview.nvim", run = "cd app && yarn install"}

    -- Appearance
    use {"kyazdani42/nvim-web-devicons"}
    use {"norcalli/nvim-colorizer.lua"}
    use {"glepnir/galaxyline.nvim"}
    use {"lukas-reineke/indent-blankline.nvim", branch = "lua"} -- TODO: make a different highlight for Python, similar to indent rainbow?
    use {"romgrk/barbar.nvim"}

    -- use {"rktjmp/lush.nvim"} -- Configuration of Lush is in appearance.lua - look into that more. See: ../TODO.md
    use {"Mofiqul/dracula.nvim"}
    use {"shaunsingh/moonlight.nvim"}
    use {"folke/tokyonight.nvim"}

    -- Utilities
    use {"folke/which-key.nvim"}
    use {"airblade/vim-rooter"}
    use {"tpope/vim-obsession"}
    use {"dhruvasagar/vim-prosession"}
    use {"kevinhwang91/nvim-hlslens"}
    use {"liuchengxu/vista.vim"}
    use {"nacro90/numb.nvim"}
    use {"folke/trouble.nvim"}
    use {
        "folke/zen-mode.nvim",
        config = function() require("zen-mode").setup {} end
    }
    use {"sudormrfbin/cheatsheet.nvim"}
    use {"tpope/vim-repeat"}
    use {"Asheq/close-buffers.vim"}
    use {"mtth/scratch.vim"}
    use {"t9md/vim-choosewin"}
    use {"troydm/zoomwintab.vim"}
    use {"psliwka/vim-smoothie"}
    use {"jeffkreeftmeijer/vim-numbertoggle"}
    use {"folke/todo-comments.nvim"}
    use {"dstein64/vim-startuptime"}
    use {"marklcrns/vim-smartq"}
    use {"inkarkat/vim-LineJuggler", requires = {"inkarkat/vim-ingo-library"}}
    use {"inkarkat/vim-visualrepeat", requires = {"inkarkat/vim-ingo-library"}}
    use {"voldikss/vim-floaterm"}
    use {"qpkorr/vim-bufkill"}
    use {"justinmk/vim-gtfo"}

    -- Text Manipulation
    use {"ervandew/supertab"}
    use {"tpope/vim-endwise"}
    use {"tpope/vim-commentary"}
    use {"tpope/vim-eunuch"}
    use {"tpope/vim-fugitive"}
    use {"windwp/nvim-spectre"}
    use {"lunarWatcher/auto-pairs"}
    use {"mizlan/iswap.nvim", config = function() require("iswap").setup {} end}
    use {"machakann/vim-sandwich"}
    use {"junegunn/vim-easy-align"}
    use {"AndrewRadev/splitjoin.vim"}
    use {"andymass/vim-matchup"}
    use {"easymotion/vim-easymotion"}
    use {"mg979/vim-visual-multi", branch = "master"}
    use {"rhysd/clever-f.vim"}
    use {"svermeulen/vim-cutlass"}
    use {"svermeulen/vim-yoink"}
    use {"itchyny/vim-cursorword"}
    use {"ntpeters/vim-better-whitespace"}
    use {"wellle/targets.vim"}
    use {"kana/vim-textobj-user"}
    use {"preservim/vim-textobj-quote"}
    use {"preservim/vim-textobj-sentence"}

    -- Git
    use {"lewis6991/gitsigns.nvim"}
    use {"pwntester/octo.nvim"}
end)
