local helpers = require("main.helpers")
local vnoremap = helpers.vnoremap
local nnoremap = helpers.nnoremap

-- Move lines/blocks intuitively using move.nvim
nnoremap("J", ":MoveLine(1)<CR>")
nnoremap("K", ":MoveLine(-1)<CR>")
vnoremap("J", ":MoveBlock(1)<CR>")
vnoremap("K", ":MoveBlock(-1)<CR>")
vnoremap("H", ":MoveHBlock(-1)<CR")
vnoremap("L", ":MoveHBlock(1)<CR>")
