local helpers = require("main.helpers")

local nmap = helpers.nmap
local noremap = helpers.noremap
local nnoremap = helpers.nnoremap
local inoremap = helpers.inoremap
local vnoremap = helpers.vnoremap
local xnoremap = helpers.xnoremap
local onoremap = helpers.onoremap

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
nnoremap("<esc>", "<Cmd>noh<cr><esc>")
inoremap("<esc>", "<Cmd>noh<cr><esc>")
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
nmap("<", "V<gv")
nmap(">", "V>gv")
xnoremap("<", "<gv")
xnoremap(">", ">gv")

-- 'm/M' actually "cuts" text and copies it to your clipboard.
-- Everything else should be blackhole'd.
nnoremap("m", "d")
xnoremap("m", "d")
nnoremap("mm", "dd")
nnoremap("M", "D")

xnoremap("c", '"_c')
nnoremap("cc", '"_S')
nnoremap("c", '"_c')
nnoremap("C", '"_C')
xnoremap("C", '"_C')
nnoremap("d", '"_d')
xnoremap("d", '"_d')
nnoremap("dd", '"_dd')
nnoremap("D", '"_D')
xnoremap("D", '"_D')
nnoremap("x", '"_x')
xnoremap("x", '"_x')
nnoremap("X", '"_X')
xnoremap("X", '"_X')

-- "SHIFT+ENTER" will continue comments, but regular "ENTER" won't
inoremap("<S-Enter>", "<C-\\><C-O>:setl fo+=r<CR><CR><C-\\><C-O>:setl fo-=r<CR>")
