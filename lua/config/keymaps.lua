-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Helper Functions
local del = vim.keymap.del
local helpers = require("config.helpers")

local nmap = helpers.nmap
local vmap = helpers.vmap
local xmap = helpers.xmap
local omap = helpers.omap
local noremap = helpers.noremap
local nnoremap = helpers.nnoremap
local inoremap = helpers.inoremap
local vnoremap = helpers.vnoremap
local xnoremap = helpers.xnoremap
local onoremap = helpers.onoremap

--[[ REMAPS ]]

-- Delete which-key keymaps that are there by default.
del("n", "<leader>w|") -- default for splitting windows vertically
del("n", "<leader>|") -- default for splitting windows vertically

-- Remove some LSP things, which will be set later in `plugins/lsp.lua`
del("n", "gh")

-- Use `<C-{h,j,k,l}>` for other things
del("n", "<C-h>")
del("n", "<C-j>")
del("n", "<C-k>")
del("n", "<C-l>")

-- Make 'J'/'K' move lines
del("n", "<A-j>")
del("n", "<A-k>")
del("i", "<A-j>")
del("i", "<A-k>")
del("v", "<A-j>")
del("v", "<A-k>")

nmap("J", "<cmd>m .+1<cr>==") -- "Move Down"
nmap("K", "<cmd>m .-2<cr>==") -- "Move Up"
vmap("J", ":m '>+1<cr>gv=gv") -- "Move Down"
vmap("K", ":m '<-2<cr>gv=gv") -- "Move Up"

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
-- Everything else should be blackhole'd because of cutlass.nvim
nnoremap("m", "d")
xnoremap("m", "d")
nnoremap("mm", "dd")
nnoremap("M", "D")

-- Don't copy things that you've pasted over
xnoremap("p", '"0p')
nnoremap("p", '"0p')
xnoremap("P", '"0P')
nnoremap("P", '"0P')

-- "SHIFT+ENTER" will continue comments, but regular "ENTER" won't
inoremap("<S-Enter>", "<C-\\><C-O>:setl fo+=r<CR><CR><C-\\><C-O>:setl fo-=r<CR>")

-- duplicate lines using LineJuggler
nmap("<A-k>", "<Plug>(LineJugglerDupOverUp)")
nmap("<A-j>", "<Plug>(LineJugglerDupOverDown)")
vmap("<A-k>", "<Plug>(LineJugglerDupOverUp):normal! gv<CR>")
vmap("<A-j>", "<Plug>(LineJugglerDupOverDown):normal! gv<CR>")
