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

-- Cursor-related changes
hi(0, "Cursor", { bg = palette.pink.bright, fg = palette.pink.bright })
hi(0, "InsertCursor", { fg = palette.fg1, bg = palette.cyan.bright })
hi(0, "VisualCursor", { fg = palette.bg1, bg = palette.orange.bright })
hi(0, "CursorLine", { bg = palette.bg1 }) -- don't show the cursor line

-- Window Borders
hi(0, "VertSplit", { fg = palette.sel0 })

