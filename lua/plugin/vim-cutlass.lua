local map = vim.api.nvim_set_keymap

-- Mappings (this is how we intentionally cut/paste from now on)
map("n", "m", "d", {noremap = true})
map("x", "m", "d", {noremap = true})
map("n", "mm", "dd", {noremap = true})
map("n", "M", "D", {noremap = true})