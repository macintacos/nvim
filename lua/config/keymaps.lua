local map = vim.keymap.set
local Cmd = require("config.helpers").Cmd

-- Unmap 'q'
map("n", "q", "<nop>", { remap = false })

-- Don't copy things you've pasted over
map("v", "p", '"_dP')

-- make 'Y' yank from current character to end of line
map("n", "Y", "y$", { desc = "Yank to Line End" })
map("v", "y", "ygv<ESC>")

-- better up/down
map({"n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({"n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({"n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({"n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({"n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({"n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({"n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({"n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move window using <C-{h,j,k,l}>
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize windows using Alt+WASD
map("n", "<A-w>", Cmd("resize +2"), { desc = "Increase Window Height" })
map("n", "<A-s>", Cmd("resize -2"), { desc = "Decrease Window Height" })
map("n", "<A-a>", Cmd("vertical resize -2"), { desc = "Decrease Window Width" })
map("n", "<A-d>", Cmd("vertical resize +2"), { desc = "Increase Window Width" })

-- Move Lines
map("n", "J", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "K", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "J", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "K", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "J", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "K", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Better indentation
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Save, no matter what
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Dupe lines up/down
map("n", "<A-j>", Cmd("t."), { desc = "Copy line down" })
map("n", "<A-k>", Cmd("t-1"),{ desc = "Copy line up" })
map("v", "<A-j>", "y`>pgv", { desc = "Copy lines down" })
map("v", "<A-k>", "y`<Pgv", { desc = "Copy line up" })
