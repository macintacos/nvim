-- [[ GLOBALS BEGIN ]]
-- This file is automatically loaded by plugins.core
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Snacks animations
-- Set to `false` to globally disable all snacks animations
vim.g.snacks_animate = true

-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }

-- Set LSP servers to be ignored when used with `util.root.detectors.lsp`
-- for detecting the LSP root
vim.g.root_lsp_ignore = { "copilot" }

-- Hide deprecation warnings
vim.g.deprecation_warnings = false

-- Show the current document symbols location from Trouble in lualine
-- You can disable this for a buffer by setting `vim.b.trouble_lualine = false`
vim.g.trouble_lualine = true

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
opt.colorcolumn = "88" -- Column color
opt.completeopt = "menu,menuone,noselect"
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.cursorline = true -- Enable highlighting of the current line
opt.expandtab = true -- Use spaces instead of tabs
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldlevel = 99
opt.foldlevel = 99
opt.foldmethod = "indent"
opt.foldtext = ""
opt.formatoptions = "jcroqlnt" -- tcqj
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.hidden = true -- Abandoned buffers are hidden instead
opt.ignorecase = true -- Ignore case
opt.ignorecase = true -- Ignore case
opt.inccommand = "nosplit" -- preview incremental substitute
opt.inccommand = "split" -- Preview replacement commands with a split window
opt.jumpoptions = "view"
opt.laststatus = 3 -- global statusline
opt.linebreak = true -- Wrap lines at convenient points
opt.list = false -- Remove characters like tabs, trailing spaces, etc.
opt.list = true -- Show some invisible characters (tabs...
opt.mouse = "a" -- Enable mouse mode
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.ruler = false -- Disable the default ruler
opt.ruler = true -- Show cursor position line and column
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = { "blank", "buffers", "curdir", "tabpages", "winsize", "winpos", "help", "globals", "skiprtp", "folds", "terminal", "localoptions" }
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true, C = true })
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
-- opt.winbar = table.concat({
--   "%#WinBar#",
--   " %.40t",
--   "%m",
--   "%r",
-- })
opt.wildmenu = true -- Command line completion stuff
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.wrap = false -- Disable line wrap

-- [[ OPTIONS END ]]
