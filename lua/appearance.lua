-- Use this file to make minor changes to the appearance of neovim, unrelated to any particular plugin
local nvim_command = vim.api.nvim_command
local colors = require("plugin.global_colors")
local api = vim.api
local hi = api.nvim_set_hl
local ns = api.nvim_create_namespace("macintacos")

api.nvim__set_hl_ns(ns)

-- Theme
nvim_command([[colorscheme dracula]])
vim.g.dracula_transparent_bg = true

-- General Things
hi(ns, "IncSearch", {fg = colors.orange, bg = colors.background_light})

-- Cursor-related changes
hi(ns, "Cursor", {bg = colors.pink, fg = colors.pink})
hi(ns, "CursorLine", {bg = colors.background_dark})
hi(ns, "CursorWord1", {bg = colors.background_light})
hi(ns, "InsertCursor", {fg = colors.foreground, bg = colors.cyan})
hi(ns, "VisualCursor", {fg = colors.background_dark, bg = colors.orange})
hi(ns, "ReplaceCursor", {fg = colors.foreground, bg = colors.red})
hi(ns, "CommandCursor", {fg = colors.foreground, bg = colors.pink})
hi(ns, "Visual", {bg = colors.background})
nvim_command([[
    set guicursor=n-c:block-Cursor
    set guicursor+=v:block-VisualCursor
    set guicursor+=i:ver100-InsertCursor
    set guicursor+=n-v-c:blinkon0
    set guicursor+=i:blinkwait10
]])

-- Whichkey
hi(ns, "WhichKeyFloat", {fg = colors.background_dark, bg = colors.background_dark})

-- Telescope Appearance
hi(ns, "TelescopeNormal", {bg = colors.background_darker})
hi(ns, "TelescopeSelection", {bg = colors.background_dark, fg = colors.green})
hi(ns, "TelescopeMatching", {fg = colors.orange, bg= colors.background_dark})
hi(ns, "TelescopePreviewMatch", {fg = colors.orange, bg = colors.background_dark})

-- barbar.nvim Appearance
hi(ns, "BufferInactive", {fg = colors.comments, bg = colors.background_dark})
hi(ns, "BufferInactiveIndex", {fg = colors.comments, bg = colors.background_dark})
hi(ns, "BufferInactiveSign", {fg = colors.comments, bg = colors.background_dark})

-- NvimTree
hi(ns, "NvimTreeCursorLine", {bg = colors.background_darker})
hi(ns, "NvimTreeNormal", {bg = colors.background_dark})
