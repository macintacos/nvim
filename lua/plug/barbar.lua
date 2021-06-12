local hi = vim.highlight.create
local colors = require("plug.global_colors")
local gvar = vim.api.nvim_set_var

-- Settings
gvar("bufferline", {auto_hide = true, icons = "both", animation = false})

-- Appearance
hi("BufferTabpageFill", {guibg = colors.tabline_bg}, false)
hi("BufferInactive", {guibg = colors.tabline_bg, guifg = colors.comment}, false)
hi('BufferInactive', {guibg = colors.tabline_bg}, false)
hi('BufferInactiveIndex', {guibg = colors.tabline_bg}, false)
hi('BufferInactiveMod', {guibg = colors.tabline_bg, guifg = colors.orange}, false)
hi('BufferInactiveSign', {guibg = colors.tabline_bg}, false)
