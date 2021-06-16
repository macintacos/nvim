local gvar = vim.api.nvim_set_var
local map = vim.api.nvim_set_keymap

gvar("smartq_default_mappings", 1)
gvar("smartq_q_filetypes", {"help"})

-- Mappings
map("n", "q", "<Plug>(smartq_this)", {})
