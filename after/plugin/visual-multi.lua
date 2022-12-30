-- Plug 'mg979/vim-visual-multi'
-- Description: multiple cursors!
local nmap = require("main.helpers").nmap
local nnoremap = require("main.helpers").nnoremap

-- custom remaps (full list: https://github.com/mg979/vim-visual-multi/wiki/Mappings)
vim.cmd([[
    let g:VM_leader = '\'
    let g:VM_mouse_mappings = 1
    let g:VM_default_mappings = 1

    " custom remaps (full list: https://github.com/mg979/vim-visual-multi/wiki/Mappings)
    let g:VM_maps = {}
    let g:VM_maps["Undo"]            = 'u'
    let g:VM_maps["Redo"]            = '<C-r>'
    let g:VM_maps["Add Cursor Down"] = '<C-j>'
    let g:VM_maps["Add Cursor Up"]   = '<C-k>'

    let g:VM_maps["Visual Add"]      = "\\a"
    let g:VM_maps["Visual Find"]     = "\\f"
    let g:VM_maps["Visual Cursors"]  = "\\c"
]])

nmap("<C-n>", "<Plug>(VM-Find-Under)")

nnoremap("<C-k>", ":call vm#commands#add_cursor_up(0, v:count1)<cr>")
nnoremap("<C-j>", ":call vm#commands#add_cursor_down(0, v:count1)<cr>")


