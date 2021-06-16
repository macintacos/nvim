local map = vim.api.nvim_set_keymap

-- Duplicating lines
map("n", "<A-j>", "<Plug>(LineJugglerDupOverDown)", {})
map("n", "<A-k>", "<Plug>(LineJugglerDupOverUp)", {})
map("v", "<A-j>", "<Plug>(LineJugglerDupOverDown)", {})
map("v", "<A-k>", "<Plug>(LineJugglerDupOverUp)", {})
