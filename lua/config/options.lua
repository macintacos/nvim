-- [[ GLOBALS BEGIN ]]
-- Loaded by init.lua before any plugin/ file is sourced.
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- Python things for neovim's usage
--[[
NOTE: to get this to work properly, it is expecting that you do the following:
    - Install `pyenv` (and the `virtualenv` subcommand if it isn't there already)
    - Run `pyenv virtualenv 3.9.10 neovim3` (can be the latest stable version, try to keep a version behind)
    - Run `pyenv activate neovim3 && pip install neovim`
    - To get the string below, run `pyenv which python`
]]
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")

-- [[ GLOBALS END ]]
--
-- [[ OPTIONS BEGIN ]]
-- Use ':help' for more information on any of these

local opt = vim.opt

opt.autoread = true -- If a file is changed, re-read it to update the view
opt.autowrite = true -- Enable auto write
-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 0 -- Show all markup characters (backticks, emphasis markers, link brackets)
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  -- Lines merely nested inside open folds get nothing; without this the fold
  -- column falls back to printing the numeric fold level next to the line number.
  foldinner = " ",
  diff = "╱",
  eob = " ",
}
opt.foldcolumn = "auto:1" -- Fold markers in the gutter, hidden when a buffer has no folds
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = "v:lua.require'config.folds'.foldtext()"
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.hidden = true -- Abandoned buffers are hidden instead
opt.ignorecase = true -- Ignore case
opt.inccommand = "split" -- Preview replacement commands with a split window
opt.jumpoptions = "view"
opt.laststatus = 3 -- global statusline
opt.linebreak = true -- Wrap lines at convenient points
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = "a" -- Enable mouse mode
opt.mousescroll = "ver:3,hor:1" -- Shift-scroll one column at a time (default hor:6 overshoots)
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.scrolloff = 10 -- Lines of context
opt.sessionoptions = {
  "blank",
  "buffers",
  "curdir",
  "tabpages",
  "winsize",
  "winpos",
  "help",
  "globals",
  "skiprtp",
  "folds",
  "terminal",
}
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true, C = true, a = true, s = true }) -- Avoid a bunch of "hit Enter" prompts
opt.showcmd = true -- Show the command in the last line of the string
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.smoothscroll = true
opt.spelllang = { "en" }
opt.splitbelow = true -- Put new windows below current
opt.splitkeep = "screen"
opt.splitright = true -- Put new windows right of current
opt.swapfile = false -- Disable the swapfile
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
opt.wildmenu = true -- Command line completion stuff
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap

-- [[ OPTIONS END ]]
