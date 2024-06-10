-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Filetype-specific settings
local autocmd = vim.api.nvim_create_autocmd

vim.cmd([[
    autocmd FileType css setlocal shiftwidth=2 softtabstop=2 tabstop=2
]])

-- Set a bunch of config files to yaml
autocmd({ "BufRead", "BufEnter" }, {
  pattern = { "*lazygit*", "*yamlfmt*", "*yamllint*" },
  callback = function()
    vim.opt_local.filetype = "yaml"
  end,
})

-- Set a bunch of config files to toml
autocmd({ "BufRead", "BufEnter" }, {
  pattern = { "*jakrc*", "*xbarrc*" },
  callback = function()
    vim.opt_local.filetype = "toml"
  end,
})
