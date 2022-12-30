require("yanky").setup({
    preserve_cursor_position = {
        enabled = true,
    },
    highlight = {
        on_put = true,
        on_yank = true,
        timer = 250,
    },
})

-- Mappings
local nnoremap = require("main.helpers").nnoremap
local xnoremap = require("main.helpers").xnoremap

nnoremap("y", "<Plug>(YankyYank)")
xnoremap("y", "<Plug>(YankyYank)")
nnoremap("p", "<Plug>(YankyPutAfter)")
xnoremap("p", "<Plug>(YankyPutAfter)")
nnoremap("P", "<Plug>(YankyPutBefore)")
xnoremap("P", "<Plug>(YankyPutBefore)")
nnoremap("gp", "<Plug>(YankyGPutAfter)")
xnoremap("gp", "<Plug>(YankyGPutAfter)")
nnoremap("gP", "<Plug>(YankyGPutBefore)")
xnoremap("gP", "<Plug>(YankyGPutBefore)")

nnoremap("<C-S-n>", "<Plug>(YankyYankCycleForward)")
nnoremap("<C-S-p>", "<Plug>(YankyYankCycleBackward)")
