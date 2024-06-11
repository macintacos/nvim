-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt

if vim.g.vscode then
  -- We do this to allow VSpaceCode to work properly
  opt.timeoutlen = 0
end

-- Use ':help' to look at what the options mean
vim.opt.autoread = true
vim.opt.colorcolumn = "88"
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.inccommand = "split" -- preview '%/s/replace/this' commands
vim.opt.list = false -- remove characters from things like tabs, trailing spaces, etc.
vim.opt.pumblend = 0
vim.opt.relativenumber = true
vim.opt.ruler = true
vim.opt.scrolloff = 5
vim.opt.shortmess:append({ a = true, c = true, s = true, I = true })
vim.opt.showcmd = true
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.timeout = true
vim.opt.title = true
vim.opt.winblend = 0
vim.opt.wildmenu = true
vim.opt.wildoptions = "pum"

-- Python things for neovim's usage
--[[
NOTE: to get this to work properly, it is expecting that you do the following:
    - Install `pyenv` (and the `virtualenv` subcommand if it isn't there already)
    - Run `pyenv virtualenv 3.9.10 neovim3` (can be the latest stable version, try to keep a version behind)
    - Run `pyenv activate neovim 3 && pip install neovim`
    - To get the string below, run `pyenv which python`
]]
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")
