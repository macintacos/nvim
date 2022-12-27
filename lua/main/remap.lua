
local helpers = require("main.helpers")

local noremap = helpers.noremap
local nnoremap = helpers.nnoremap
local inoremap = helpers.inoremap
local vnoremap = helpers.vnoremap
local xnoremap = helpers.xnoremap
local onoremap = helpers.onoremap
local flexnoremap = helpers.flexnoremap

--[[ REMAPS ]]

-- C-s saves in all modes
nnoremap("<C-s>", "<Cmd>w<CR>")
inoremap("<C-s>", "<Cmd>w<CR>")
vnoremap("<C-s>", "<Cmd>w<CR>")
xnoremap("<C-s>", "<Cmd>w<CR>")

-- Move to window using the arrow keys
nnoremap("<left>", "<C-w>h")
nnoremap("<down>", "<C-w>j")
nnoremap("<up>", "<C-w>k")
nnoremap("<right>", "<C-w>l")

-- Resize window using shift+arrow keys
nnoremap("<S-Up>", "<cmd>resize +3<CR>")
nnoremap("<S-Down>", "<cmd>resize -3<CR>")
nnoremap("<S-Left>", "<cmd>vertical resize -3<CR>")
nnoremap("<S-Right>", "<cmd>vertical resize +3<CR>")

-- j/k moves visually up and down lines, until you want to jump lines.
-- This is more intuitive than the default behavior.
noremap("j", "( v:count? 'j': 'gj')", { expr = true, noremap = true })
noremap("k", "( v:count? 'k': 'gk')", { expr = true, noremap = true })

-- make 'Y' yank from current character to end of line
noremap("Y", "y$")
vnoremap("y", "ygv<ESC>")

-- Horizontal scrolling when wrapped
nnoremap("<C-l>", "20zl")
nnoremap("<C-h>", "20zh")

-- 'zz'-based mappings - center after performing an action
nnoremap("G", "Gzz")
nnoremap("<C-d>", "<C-d>zz")
nnoremap("<C-u>", "<C-u>zz")
nnoremap("n", "nzzzv") 
nnoremap("N", "Nzzzv")

-- Clear search with <esc>
flexnoremap("<esc>", "<Cmd>noh<cr><esc>", { "i", "n" })
nnoremap("gw", "*N")
xnoremap("gw", "*N")

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
nnoremap("n", "'Nn'[v:searchforward]", { expr = true })
xnoremap("n", "'Nn'[v:searchforward]", { expr = true })
onoremap("n", "'Nn'[v:searchforward]", { expr = true })
nnoremap("N", "'nN'[v:searchforward]", { expr = true })
xnoremap("N", "'nN'[v:searchforward]", { expr = true })
onoremap("N", "'nN'[v:searchforward]", { expr = true })

-- Better indenting
vnoremap("<", "<gv")
vnoremap(">", ">gv")
