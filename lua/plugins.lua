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

    -- Language Features
    use {"nvim-treesitter/nvim-treesitter", run = ":TSUpdate"}
    use {"romgrk/nvim-treesitter-context"}
    use {"neoclide/coc.nvim", branch = "release"}
    use {"puremourning/vimspector"}

    -- Language specific
    -- Appearance
    use {"kyazdani42/nvim-web-devicons"}
    use {"Mofiqul/dracula.nvim"}

    -- Text Manipulation
    -- Git
    -- Utilities
end)
