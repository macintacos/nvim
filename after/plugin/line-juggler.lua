local helpers = require("main.helpers")
local nmap = helpers.nmap
local vmap = helpers.vmap

-- duplicate lines using LineJuggler
nmap("<M-k>", "<Plug>(LineJugglerDupOverUp)")
nmap("<M-j>", "<Plug>(LineJugglerDupOverDown)")
vmap("<M-k>", "<Plug>(LineJugglerDupOverUp):normal! gv<CR>")
vmap("<M-j>", "<Plug>(LineJugglerDupOverDown):normal! gv<CR>")

