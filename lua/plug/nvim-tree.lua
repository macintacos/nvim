local gvar = vim.api.nvim_set_var
local hi = vim.highlight.create
local colors = require("plug.global_colors")

-- Options
gvar("nvim_tree_side", "right")
gvar("nvim_tree_width", 40)

-- Appearance
hi("NvimTreeNormal", {guibg=colors.tabline_bg})