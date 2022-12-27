require("neodev").setup({
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
