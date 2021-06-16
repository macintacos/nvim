local gvar = vim.api.nvim_set_var
local map = vim.api.nvim_set_keymap

-- Settings
gvar("clever_f_show_prompt", 1)
gvar("clever_f_smart_case", 1)

-- Mappings
map("n", "<ESC>", "<Plug>(clever-f-reset)", {silent = true})

