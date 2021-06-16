local map = vim.api.nvim_set_keymap
local gvar = vim.api.nvim_set_var

gvar("mapleader", " ")
gvar("maplocalleader", ",")

-- get me out
map("i", "jj", "<ESC>", {})
map("i", "kk", "<ESC>", {})

-- make j/k behave properly
map("n", "<C-s>", "<Cmd>w<CR>", {noremap = true})
map("i", "<C-s>", "<Cmd>w<CR>", {noremap = true})
map("v", "<C-s>", "<Cmd>w<CR>", {noremap = true})
map("x", "<C-s>", "<Cmd>w<CR>", {noremap = true})

-- make 'Y' yank from current character to end of line
map("", "Y", "y$", {})
map("v", "y", "ygv<ESC>", {})

-- navigate splits with 'TAB'
map("n", "<TAB>", "<C-w>w", {noremap = true, silent = true})
map("n", "<S-TAB>", "<C-w>W", {noremap = true, silent = true})

-- increase/decrease window size
map("n", "<M-w>", "<Cmd>resize +5<CR>", {noremap = true, silent = true})
map("n", "<M-s>", "<Cmd>resize -5<CR>", {noremap = true, silent = true})
map("n", "<M-d>", "<Cmd>vertical resize +5<CR>", {noremap = true, silent = true})
map("n", "<M-a>", "<Cmd>vertical resize -5<CR>", {noremap = true, silent = true})

-- better indentation selection stuff
map("v", "<", "<gv", {noremap = true})
map("v", ">", ">gv", {noremap = true})
map("v", "<S-TAB>", "<gv", {noremap = true})
map("v", "<TAB>", ">gv", {noremap = true})

-- Horizontal scrolling when wrapped
map("n", "<C-l>", "20zl", {noremap = true})
map("n", "<C-h>", "20zh", {noremap = true})

-- improved movements
map("n", "G", "Gzz", {})
map("n", "H", "^", {})
map("n", "L", "$", {})

-- Moving lines
map("n", "J", ":m .+1<CR>==", {})
map("v", "K", ":m '<-2<CR>gv=gv", {})
map("n", "K", ":m .-2<CR>==", {})
map("v", "J", ":m '>+1<CR>gv=gv", {})

