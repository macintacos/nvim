-- Set leader keys as eary as possible.
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.cmd([[
    let g:VM_leader = '\'
    let g:VM_default_mappings = 0
]])

require("main")
