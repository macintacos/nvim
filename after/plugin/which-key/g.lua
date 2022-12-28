local wk = require("which-key")

wk.register({
    d = { "<Cmd>TroubleToggle lsp_definitions<CR>", "Go to Definition" },
    h = { "<Cmd>lua vim.lsp.buf.hover()<CR>", "Show Hover" },
    i = { "<Cmd>lua vim.lsp.buf.implementation()<CR>", "Go to Implementation" },
    o = { "<Cmd>lua vim.lsp.buf.type_definition()<CR>", "Go to Type Definition" },
    r = { "<Cmd>TroubleToggle lsp_references<CR>", "Go to References" },
    s = { "<Plug>(leap-cross-window)", "Leap Across Windows" },

    D = { "<Cmd>lua vim.lsp.buf.declaration()<CR>", "Go to Declaration" },
}, { prefix = "g" })
