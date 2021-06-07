local opt = vim.opt -- Meta-accessor - prefer this
local nvim_command = vim.api.nvim_command

-- Use ``':help' to look at what the options mean
opt.clipboard:prepend{"unnamedplus"}
opt.wildmode = {"longest:full", "full"}
opt.autoindent = true
opt.autoread = true
opt.cmdheight = 2
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.hidden = true
opt.ignorecase = true
opt.laststatus = 2
opt.linebreak = true
opt.mouse = "a"
opt.wrap = false
opt.relativenumber = true
opt.ruler = true
opt.scrolloff = 20
opt.shiftwidth = 4
opt.shortmess:append({a = true, c = true, s = true})
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
opt.updatetime = 300 -- smaller updatetime for CursorHold & CursorHoldI
opt.wildmenu = true


-- For things that can't be cleanly set with neovim's lua API
nvim_command([[
    set whichwrap+=<,>,[,],h,l
    set gcr=a:block
    set gcr+=o:hor50-Cursor
    set gcr+=n:Cursor
    set gcr+=i-ci-sm:InsertCursor
    set gcr+=i:ver100-iCursor
    set gcr+=r-cr:ReplaceCursor-hor20
    set gcr+=c:CommandCursor
    set gcr+=v-ve:VisualCursor
    set gcr+=a:blinkon0
]])

-- Filetype-specific settings
nvim_command([[
    autocmd FileType css setlocal shiftwidth=2 softtabstop=2 tabstop=2
    autocmd FileType markdown setlocal textwidth=90
]])

-- Highlight the line when yanking
nvim_command([[
    autocmd TextYankPost * silent! lua vim.highlight.on_yank{higroup="IncSearch", timeout=300}
]])

