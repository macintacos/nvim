vim.opt.background = "dark" -- set this to dark or light

-- Theme
vim.cmd([[colorscheme nightfox]])

-- Use this file to make minor changes to the appearance of neovim, unrelated to any particular plugin
-- Nightfox palette: https://github.com/EdenEast/nightfox.nvim/blob/main/lua/nightfox/palette/nightfox.lua
local hi = vim.api.nvim_set_hl
local palette = require("nightfox.palette").load("nightfox")

vim.cmd([[
    " Don't highlight word under cursor when using mini.cursor plugin module
    hi! link MiniCursorword Visual
    hi! MiniCursorwordCurrent gui=nocombine guifg=NONE guibg=NONE
]])

-- Window Borders
hi(0, "VertSplit", { fg = palette.sel0 })
