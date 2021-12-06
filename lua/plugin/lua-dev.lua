require("lua-dev").setup({
    library = {
        plugins = true,
    },
    lspconfig = {
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim" },
                },
            },
        },
    },
})
