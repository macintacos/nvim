local wk = require("which-key")

wk.register({
    a = { "<Cmd>lua vim.lsp.buf.code_action()<CR>", "Show Code Actions" },
    b = { "<Plug>(VM-Find-Under)", "Add Cursor for Word" },
    B = { "<Cmd>call vm#commands#find_all(0, 1)<CR>", "Add Cursor to All Words" },
    d = { "<Cmd>TroubleToggle lsp_definitions<CR>", "Go to Definition" },
    h = { "<Cmd>lua vim.lsp.buf.hover()<CR>", "Show Hover" },
    i = { "<Cmd>lua vim.lsp.buf.implementation()<CR>", "Go to Implementation" },
    l = { "<Cmd>lua vim.lsp.buf.open_float()<CR>", "Show Diagnostic Float" },
    n = {
        name = "next",
        n = { "gn", "Search Forwards and Select" },
        s = { "<Cmd>AerialNext<CR>", "Go to Next Symbol" }
    },
    N = {
        name = "prev",
        n = { "gN", "Search Backwards and Select" },
        s = { "<Cmd>AerialPrev<CR>", "Go to Prev Symbol" }
    },
    o = { "<Cmd>lua vim.lsp.buf.type_definition()<CR>", "Go to Type Definition" },
    r = { "<Cmd>TroubleToggle lsp_references<CR>", "Go to References" },
    s = { "<Plug>(leap-cross-window)", "Leap Across Windows" },

    D = { "<Cmd>lua vim.lsp.buf.declaration()<CR>", "Go to Declaration" },
}, { prefix = "g" })
