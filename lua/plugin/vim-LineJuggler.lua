local map = vim.api.nvim_set_keymap

-- Duplicating lines
map("n", "<M-j>", "<Plug>(LineJugglerDupOverDown)", { silent = true })
map("n", "<M-k>", "<Plug>(LineJugglerDupOverUp)", { silent = true })
map("v", "<M-j>", "<Plug>(LineJugglerDupOverDown):normal! gv<CR>", { silent = true })
map("v", "<M-k>", "<Plug>(LineJugglerDupOverUp):normal! gv<CR>", { silent = true })
