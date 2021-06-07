-- ref: https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#pyright
require'lspconfig'.pyright.setup {
    on_attach = require("lsp").common_on_attach,
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true
            }
        }
    }
}
