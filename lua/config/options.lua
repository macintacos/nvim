-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt

-- Use ':help' to look at what the options mean
opt.autoread = true
opt.colorcolumn = "88"
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.hidden = true
opt.inccommand = "split" -- preview '%/s/replace/this' commands
opt.list = false -- remove characters from things like tabs, trailing spaces, etc.
opt.pumblend = 0
opt.relativenumber = true
opt.ruler = true
opt.scrolloff = 5
opt.shortmess:append({ a = true, c = true, s = true, I = true })
opt.showcmd = true
opt.showmode = false
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.termguicolors = true
opt.timeout = true
opt.title = true
opt.winblend = 0
opt.wildmenu = true
opt.wildoptions = "pum"

-- Python things for neovim's usage
--[[
NOTE: to get this to work properly, it is expecting that you do the following:
    - Install `pyenv` (and the `virtualenv` subcommand if it isn't there already)
    - Run `pyenv virtualenv 3.9.10 neovim3` (can be the latest stable version, try to keep a version behind)
    - Run `pyenv activate neovim 3 && pip install neovim`
    - To get the string below, run `pyenv which python`
]]
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")
