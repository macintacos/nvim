-- Global Options
local opt = vim.opt -- Meta-accessor - prefer this
local TERMINAL = vim.fn.expand("$TERMINAL")

-- Use ':help' to look at what the options mean
opt.autoindent = true
opt.autoread = true
opt.clipboard:prepend({ "unnamedplus" })
opt.colorcolumn = "9999"
opt.completeopt = "menuone,noselect"
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.hidden = true
opt.ignorecase = true
opt.inccommand = "split" -- preview '%/s/replace/this' commands
opt.laststatus = 2
opt.linebreak = true
opt.mouse = "nvi"
opt.number = true
opt.pumblend = 15
opt.relativenumber = true
opt.ruler = true
opt.scrolloff = 5
opt.shiftwidth = 4
opt.shortmess:append({ a = true, c = true, s = true })
opt.showcmd = true
opt.showmode = false
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.softtabstop = 4
opt.splitbelow = true
opt.splitright = true
opt.tabstop = 4
opt.termguicolors = true
opt.timeoutlen = 250 -- important for which-key
opt.title = true
opt.undodir = vim.fn.expand("$HOME") .. "/.vim/undo"
opt.undofile = true
opt.updatetime = 50 -- smaller updatetime for CursorHold & CursorHoldI
opt.wildmenu = true
opt.wildmode = { "longest:full", "full" }
opt.wildoptions = "pum"
opt.wrap = false

-- Setting up the title, maybe
vim.cmd('let &titleold="' .. TERMINAL .. '"')

-- Filetype-specific settings
vim.cmd([[
    autocmd FileType css setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType markdown setlocal textwidth=90
]])

