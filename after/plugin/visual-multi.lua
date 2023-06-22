-- Plug 'mg979/vim-visual-multi'
-- Description: multiple cursors!
local nmap = require("main.helpers").nmap
local nnoremap = require("main.helpers").nnoremap

-- custom remaps (full list: https://github.com/mg979/vim-visual-multi/wiki/Mappings)
nnoremap("<C-k>", "<Plug>(VM-Add-Cursor-Up)")
nnoremap("<C-j>", "<Plug>(VM-Add-Cursor-Down)")
