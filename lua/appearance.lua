-- Use this file to make minor changes to the appearance of neovim, unrelated to any particular plugin
local nvim_command = vim.api.nvim_command
local colors = require("plugin.global_colors")
local api = vim.api
local hi = api.nvim_set_hl
local ns = api.nvim_create_namespace("macintacos")

api.nvim__set_hl_ns(ns)

-- Theme Settings
-- NOTE: Needs to be called _before_ the colorscheme is loaded
vim.g.dracula_transparent_bg = true

-- Load the theme
vim.cmd([[colorscheme dracula]])

-- Other colors
-- General Things
hi(ns, "IncSearch", { fg = colors.orange, bg = colors.background_light })

-- Cursor-related changes
hi(ns, "Cursor", { bg = colors.pink, fg = colors.pink })
hi(ns, "CursorLine", { bg = colors.background })
hi(ns, "CursorWord1", { bg = colors.background_light })
hi(ns, "InsertCursor", { fg = colors.foreground, bg = colors.cyan })
hi(ns, "VisualCursor", { fg = colors.background_dark, bg = colors.orange })
hi(ns, "ReplaceCursor", { fg = colors.foreground, bg = colors.red })
hi(ns, "CommandCursor", { fg = colors.foreground, bg = colors.pink })
hi(ns, "Visual", { bg = colors.background })
nvim_command([[
    set guicursor=n-c:block-Cursor
    set guicursor+=v:block-VisualCursor
    set guicursor+=i:ver100-InsertCursor
    set guicursor+=n-v-c:blinkon0
    set guicursor+=i:blinkwait10
]])
