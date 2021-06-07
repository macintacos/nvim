-- Use this file to make minor changes to the appearance of neovim, unrelated to any particular plugin
local nvim_command = vim.api.nvim_command

-- Theme
nvim_command([[colorscheme dracula]])

-- cursor-related changes
nvim_command([[
    hi CursorLine guibg=#2e3140
    hi Cursor  guifg=#ff79c6 guibg=#ff79c6
    hi InsertCursor  guifg=#fdf6e3 guibg=#2aa198
    hi VisualCursor  guifg=#fdf6e3 guibg=#ffb86c
    hi ReplaceCursor guifg=#fdf6e3 guibg=#dc322f
    hi CommandCursor guifg=#fdf6e3 guibg=#ff5555
]])

-- Visual styling
nvim_command([[
    hi Visual guibg=#393d4f
]])

-- Styling when entering/leaving INSERT
nvim_command([[
    autocmd InsertEnter * highlight CursorLine guibg=#282a36
    autocmd InsertEnter * highlight Cursor guifg=#ff79c6 guibg=#ff79c6
    autocmd InsertLeave * highlight CursorLine guibg=#2e3140
    autocmd InsertLeave * highlight Cursor guifg=#ff79c6 guibg=#ff79c6
]])
