local map = vim.api.nvim_set_keymap
local gvar = vim.api.nvim_set_var

gvar("mapleader", " ")
gvar("maplocalleader", ",")

-- misc. things
map("n", ";", ":", { noremap = true })

-- make j/k behave properly
map("n", "<C-s>", "<Cmd>w<CR>", { noremap = true })
map("i", "<C-s>", "<Cmd>w<CR>", { noremap = true })
map("v", "<C-s>", "<Cmd>w<CR>", { noremap = true })
map("x", "<C-s>", "<Cmd>w<CR>", { noremap = true })

-- make 'Y' yank from current character to end of line
map("", "Y", "y$", {})
map("v", "y", "ygv<ESC>", {})

-- -- navigate splits with 'TAB'
-- map("n", "<TAB>", "<C-w>w", {noremap = true, silent = true})
-- map("n", "<S-TAB>", "<C-w>W", {noremap = true, silent = true})

-- increase/decrease window size
map("n", "<M-w>", "<Cmd>resize +5<CR>", { noremap = true, silent = true })
map("n", "<M-s>", "<Cmd>resize -5<CR>", { noremap = true, silent = true })
map("n", "<M-d>", "<Cmd>vertical resize +5<CR>", { noremap = true, silent = true })
map("n", "<M-a>", "<Cmd>vertical resize -5<CR>", { noremap = true, silent = true })

-- better indentation selection stuff
map("v", "<S-TAB>", "<gv", { noremap = true })
map("v", "<TAB>", ">gv", { noremap = true })

-- Horizontal scrolling when wrapped
map("n", "<C-l>", "20zl", { noremap = true })
map("n", "<C-h>", "20zh", { noremap = true })

-- improved movements
map("n", "G", "Gzz", {})

-- move.nvim
map("n", "J", ":MoveLine(1)<CR>", { noremap = true, silent = true })
map("n", "K", ":MoveLine(-1)<CR>", { noremap = true, silent = true })
map("v", "J", ":MoveBlock(1)<CR>", { noremap = true, silent = true })
map("v", "K", ":MoveBlock(-1)<CR>", { noremap = true, silent = true })
map("n", "L", ":MoveHChar(1)<CR>", { noremap = true, silent = true })
map("n", "H", ":MoveHChar(-1)<CR>", { noremap = true, silent = true })
map("v", "L", ":MoveHBlock(1)<CR>", { noremap = true, silent = true })
map("v", "H", ":MoveHBlock(-1)<CR>", { noremap = true, silent = true })

-- vim-mundo
map("n", "U", "<Cmd>MundoShow<CR>", { noremap = true })
