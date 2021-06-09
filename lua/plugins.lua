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

-- Plugins specified here!
return require("packer").startup(function(use)
    -- Get Packer to manage itself
    use {"wbthomason/packer.nvim"}

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
    use {"tpope/vim-endwise"}

    -- Language Features
    use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}
    use {"romgrk/nvim-treesitter-context"}
    use {"neoclide/coc.nvim", branch = "release"}
    use {"puremourning/vimspector"}
    use {"kkoomen/vim-doge", run = ":call doge#install()"}

    -- Language specific
    use {"fatih/vim-go", run = ":GoUpdateBinaries"}

    -- Appearance
    use {"kyazdani42/nvim-web-devicons"}
    use {"norcalli/nvim-colorizer.lua"}
    use {"glepnir/galaxyline.nvim"}
    use {"lukas-reineke/indent-blankline.nvim", branch = "lua"} -- TODO: make a different highlight for Python, similar to indent rainbow?
    -- use {"akinsho/nvim-bufferline.lua"}
    use {"romgrk/barbar.nvim"}
    use {"glepnir/dashboard-nvim"}

    use {"rktjmp/lush.nvim"} -- Configuration of Lush is in appearance.lua
    use {"Mofiqul/dracula.nvim"}
    use {"shaunsingh/moonlight.nvim"}
    use {"folke/tokyonight.nvim"}

    -- Text Manipulation
    -- Git
    -- Utilities
end)
