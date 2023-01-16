local wk = require("which-key")
local cmd = require("main.helpers").cmd

wk.register({
    a = { cmd("lua vim.lsp.buf.code_action()"), "Show Code Actions" },
    b = { "<Plug>(VM-Find-Under)", "Add Cursor for Word" },
    B = { cmd("call vm#commands#find_all(0, 1)"), "Add Cursor to All Words" },
    d = { cmd("TroubleToggle lsp_definitions"), "Go to Definition" },
    h = { cmd("lua vim.lsp.buf.hover()"), "Show Hover" },
    i = { cmd("lua vim.lsp.buf.implementation()"), "Go to Implementation" },
    l = { cmd("lua vim.lsp.buf.open_float()"), "Show Diagnostic Float" },
    n = {
        name = "next",
        n = { "gn", "Search Forwards and Select" },
        s = { cmd("AerialNext"), "Go to Next Symbol" }
    },
    N = {
        name = "prev",
        n = { "gN", "Search Backwards and Select" },
        s = { cmd("AerialPrev"), "Go to Prev Symbol" }
    },
    o = { cmd("lua vim.lsp.buf.type_definition()"), "Go to Type Definition" },
    r = { cmd("TroubleToggle lsp_references"), "Go to References" },
    s = { "<Plug>(leap-cross-window)", "Leap Across Windows" },

    D = { cmd("lua vim.lsp.buf.declaration()"), "Go to Declaration" },
}, { prefix = "g" })
