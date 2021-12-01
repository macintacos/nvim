local map = vim.api.nvim_set_keymap

-- Duplicating lines
map("n", "<A-j>", "<Plug>(LineJugglerDupOverDown)", {silent = true})
map("n", "<A-k>", "<Plug>(LineJugglerDupOverUp)", {silent = true})
map("v", "<A-j>", "<Plug>(LineJugglerDupOverDown):normal! gv<CR>", {silent = true})
map("v", "<A-k>", "<Plug>(LineJugglerDupOverUp):normal! gv<CR>", {silent = true})
