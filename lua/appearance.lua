-- Use this file to make minor changes to the appearance of neovim, unrelated to any particular plugin
local gvar = vim.api.nvim_set_var
local api = vim.api
local hi = api.nvim_set_hl

---@alias theme_type
---| 'dark' # Theme is set to dark mode
---| 'light' # Theme is set to light mode

---@param theme_type theme_type
local function set_highlights(theme_type)
    local colors = require("plugin.global_colors")[theme_type]

    hi(0, "IncSearch", { fg = colors.orange, bg = colors.background_light })

    -- Cursor-related changes
    hi(0, "Cursor", { bg = colors.pink, fg = colors.pink })
    hi(0, "CursorLine", { bg = colors.background_dark })
    hi(0, "CursorWord1", { bg = colors.background_light })
    hi(0, "InsertCursor", { fg = colors.foreground, bg = colors.cyan })
    hi(0, "VisualCursor", { fg = colors.background_dark, bg = colors.orange })
    hi(0, "ReplaceCursor", { fg = colors.foreground, bg = colors.red })
    hi(0, "CommandCursor", { fg = colors.foreground, bg = colors.pink })
    hi(0, "Visual", { fg = colors.orange, bg = colors.background_light })
    vim.cmd([[
        set guicursor=n-c:block-Cursor
        set guicursor+=v:block-VisualCursor
        set guicursor+=i:ver100-InsertCursor
        set guicursor+=n-v-c:blinkon0
        set guicursor+=i:blinkwait10
    ]])

    -- Choosewin
    gvar("choosewin_color_label", { gui = { colors.purple, colors.background, "bold" } })
    gvar("choosewin_color_overlay", { gui = { colors.purple, colors.purple, "bold" } })
    gvar("choosewin_color_label_current", { gui = { colors.green, colors.background, "bold" } })
    gvar("choosewin_color_overlay_current", { gui = { colors.green, colors.green, "bold" } })
    gvar("choosewin_color_share", { gui = { colors.background, colors.background_light, "bold" } })

    -- Telescope
    hi(0, "TelescopeNormal", { bg = colors.background_darker })
    hi(0, "TelescopeSelection", { bg = colors.background_dark, fg = colors.green })
    hi(0, "TelescopeMatching", { fg = colors.orange, bg = colors.background_dark })
    hi(0, "TelescopePreviewMatch", { fg = colors.orange, bg = colors.background_dark })
    hi(0, "TelescopeMultiSelection", { fg = colors.orange, bg = colors.background_dark })
    hi(0, "TelescopePromptPrefix", { fg = colors.green })
    hi(0, "TelescopeSelection", { fg = colors.purple })

    -- Bufferline
    hi(0, "BufferLineSeparator", { fg = colors.background_light })

    -- NvimTree
    hi(0, "NvimTreeCursorLine", { fg = colors.foreground })
    hi(0, "NvimTreeNormal", { fg = colors.foreground })
    hi(0, "NvimTreeRootFolder", { bg = colors.background_darker, fg = colors.background_darker })

    -- Whichkey
    hi(0, "WhichKeyFloat", { fg = colors.background_dark, bg = colors.background_dark })
end

-- Setup themes
require("lualine").setup({ options = { theme = "auto" } })

local auto_dark_mode = require("auto-dark-mode")

auto_dark_mode.setup({
    update_interval = 1000,
    set_dark_mode = function()
        local dracula = require("dracula")
        dracula.setup({
            transparent_bg = true,
            lualine_bg_color = require("plugin.global_colors").dark.background_darker,
        })

        vim.cmd([[colorscheme dracula]])
        set_highlights("dark")
    end,
    set_light_mode = function()
        vim.api.nvim_set_option("background", "light")

        vim.cmd([[colorscheme onehalflight]])
        set_highlights("light")
    end,
})

auto_dark_mode.init()
