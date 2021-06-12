local map = vim.api.nvim_set_keymap
local gvar = vim.api.nvim_set_var
local colors = require("plug.global_colors")

-- Options
gvar("choosewin_overlay_enable", 1) -- TODO: Figure out how to get rid of the blanklines: https://github.com/lukas-reineke/indent-blankline.nvim/issues/123
gvar("choosewin_statusline_replace", 0)

-- Appearance
gvar("choosewin_color_label",           { gui = {colors.purple, colors.bg, "bold" } })
gvar("choosewin_color_overlay",         { gui = {colors.purple, colors.purple, "bold" } })
gvar("choosewin_color_label_current",   { gui = {colors.green, colors.bg, "bold" } })
gvar("choosewin_color_overlay_current", { gui = {colors.green, colors.green, "bold" } })
gvar("choosewin_color_share",           { gui = {colors.bg, colors.section_bg, "bold" } })

-- Mappings
map("n", "-", "<Plug>(choosewin)", {})