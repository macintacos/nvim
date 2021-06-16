local hi = vim.highlight.create
local colors = require("plug.global_colors")
local gvar = vim.api.nvim_set_var
local map = vim.api.nvim_set_keymap

-- Settings
gvar("bufferline", {auto_hide = true, icons = "both", animation = false})

-- Appearance
hi("BufferTabpageFill", {guibg = colors.tabline_bg}, false)
hi("BufferInactive", {guibg = colors.tabline_bg, guifg = colors.comment}, false)
hi('BufferInactive', {guibg = colors.tabline_bg}, false)
hi('BufferInactiveIndex', {guibg = colors.tabline_bg}, false)
hi('BufferInactiveMod', {guibg = colors.tabline_bg, guifg = colors.orange}, false)
hi('BufferInactiveSign', {guibg = colors.tabline_bg}, false)

-- Mappings
map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", {noremap = true})
map("n", "<A-.>", "<Cmd>BufferNext<CR>", {noremap = true})
map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", {noremap = true})
map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", {noremap = true})
