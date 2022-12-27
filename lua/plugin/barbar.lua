local gvar = vim.api.nvim_set_var
local map = vim.api.nvim_set_keymap

-- Settings
gvar("bufferline", {auto_hide = true, icons = "both", animation = false})

-- Mappings
map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", {noremap = true})
map("n", "<A-.>", "<Cmd>BufferNext<CR>", {noremap = true})
map("n", "<A-<>", "<Cmd>BufferMovePrevious<CR>", {noremap = true})
map("n", "<A->>", "<Cmd>BufferMoveNext<CR>", {noremap = true})

-- Appearance
hi(ns, "BufferInactive", {fg = colors.comments, bg = colors.background_dark})
hi(ns, "BufferInactiveIndex", {fg = colors.comments, bg = colors.background_dark})
hi(ns, "BufferInactiveSign", {fg = colors.comments, bg = colors.background_dark})
