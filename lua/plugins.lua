-- Bootstrap packer
local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.api.nvim_command("!git clone https://github.com/wbthomason/packer.nvim " ..
                     install_path)
    vim.api.nvim_command "packadd packer.nvim"
end

-- Compile when there are changes to this file
vim.cmd "autocmd BufWritePost plugins.lua PackerCompile"

-- Plugins specified here!
return require("packer").startup(function(use)
    -- Get Packer to manage itself
    use 'wbthomason/packer.nvim'

    -- Essential
    -- Language Features
    -- Language specific
    -- Appearance
    -- Text Manipulation
    -- Git
    -- Utilities
end)
