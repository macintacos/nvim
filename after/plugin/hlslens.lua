require("hlslens").setup({
    calm_down = true,
    nearest_float_when = "never", -- FIXME: This should not show the lens for the current match, but it's not working
})

-- Mappings
local nnoremap = require("main.helpers").nnoremap

nnoremap(
    "n",
    "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>"
)
nnoremap(
    "N",
    "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>"
)

nnoremap("*", "*<Cmd>lua require('hlslens').start()<CR>")
nnoremap("g*", "g*<Cmd>lua require('hlslens').start()<CR>")
nnoremap("#", "#<Cmd>lua require('hlslens').start()<CR>")
nnoremap("g#", "g#<Cmd>lua require('hlslens').start()<CR>")
