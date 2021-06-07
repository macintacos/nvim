-- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#gopls
require'lspconfig'.gopls.setup {on_attach = require("lsp").common_on_attach}
