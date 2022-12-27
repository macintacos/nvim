--[[ TODOS

TODO: move the FileType commands to their own dedicated files (after/ftplugin? idk)

--]]

-- Use ':help' to look at what the options mean
vim.opt.autoindent = true
vim.opt.autoread = true
vim.opt.clipboard:prepend({ "unnamedplus" })
vim.opt.colorcolumn = "9999"
vim.opt.completeopt = "menuone,noselect"
vim.opt.confirm = true
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.ignorecase = true
vim.opt.inccommand = "split" -- preview '%/s/replace/this' commands
vim.opt.laststatus = 2
vim.opt.linebreak = true
vim.opt.mouse = "nvi"
vim.opt.number = true
vim.opt.pumblend = 15
vim.opt.relativenumber = true
vim.opt.ruler = true
vim.opt.scrolloff = 5
vim.opt.shiftwidth = 4
vim.opt.shortmess:append({ a = true, c = true, s = true })
vim.opt.showcmd = true
vim.opt.showmode = false
vim.opt.signcolumn = "yes"
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.softtabstop = 4
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.timeout = true
vim.opt.timeoutlen = 250 -- important for which-key
vim.opt.title = true
vim.opt.undodir = vim.fn.expand("$HOME") .. "/.vim/undo"
vim.opt.undofile = true
vim.opt.updatetime = 50 -- smaller updatetime for CursorHold & CursorHoldI
vim.opt.wildmenu = true
vim.opt.wildmode = { "longest:full", "full" }
vim.opt.wildoptions = "pum"
vim.opt.wrap = false

-- Filetype-specific settings
vim.cmd([[
    autocmd FileType css setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType markdown setlocal textwidth=90
]])

