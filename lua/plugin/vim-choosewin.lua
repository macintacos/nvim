-- More in viml/plug/choosewin
local map = vim.api.nvim_set_keymap
local gvar = vim.api.nvim_set_var

-- Options
gvar("choosewin_overlay_enable", 1) -- TODO: Figure out how to get rid of the blanklines: https://github.com/lukas-reineke/indent-blankline.nvim/issues/123
gvar("choosewin_statusline_replace", 0)

-- Mappings
map("n", "-", "<Plug>(choosewin)", {})
