require("lspconfig").jsonls.setup {
    cmd = {
        "node",
        DATA_PATH ..
            "/lspinstall/json/vscode-json/json-language-features/server/dist/node/jsonServerMain.js",
        "--stdio"
    },
    on_attach = require'lsp'.common_on_attach
}
