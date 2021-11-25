local map = vim.api.nvim_set_keymap
local gvar = vim.api.nvim_set_var
local global_colors = require("plug.global_colors")

-- Options
gvar("choosewin_overlay_enable", 1) -- TODO: Figure out how to get rid of the blanklines: https://github.com/lukas-reineke/indent-blankline.nvim/issues/123
gvar("choosewin_statusline_replace", 0)

-- Appearance
gvar("choosewin_color_label",           { gui = {global_colors.purple, global_colors.background, "bold" } })
gvar("choosewin_color_overlay",         { gui = {global_colors.purple, global_colors.purple, "bold" } })
gvar("choosewin_color_label_current",   { gui = {global_colors.green, global_colors.background, "bold" } })
gvar("choosewin_color_overlay_current", { gui = {global_colors.green, global_colors.green, "bold" } })
gvar("choosewin_color_share",           { gui = {global_colors.background, global_colors.background_light, "bold" } })

-- Mappings
map("n", "-", "<Plug>(choosewin)", {})