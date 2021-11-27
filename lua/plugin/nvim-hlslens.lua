local map = vim.api.nvim_set_keymap

-- Settings
require("hlslens").setup({
    calm_down = true,
    nearest_only = true
})

-- Mappings
map("n", "n", "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>", {silent = true})
map("n", "N", "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>", {silent = true})
map("n", "*", "*<Cmd>lua require('hlslens').start()<CR>", {})
map("n", "g*", "g*<Cmd>lua require('hlslens').start()<CR>", {})
map("n", "#", "#<Cmd>lua require('hlslens').start()<CR>", {})
map("n", "g#", "g#<Cmd>lua require('hlslens').start()<CR>", {})

