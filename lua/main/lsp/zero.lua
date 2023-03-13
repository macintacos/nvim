local M = {}
local lsp = require("lsp-zero")
local nnoremap = require("main.helpers").nnoremap

-- Client-specific settings
lsp.on_attach(function(client, bufnr)
    -- Mappings
    nnoremap("gh", "<Cmd>lua vim.lsp.buf.hover()<CR>")
end)

lsp.preset("recommended")

-- To choose more, see: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
lsp.ensure_installed({
    "astro",
    "bashls",
    "cmake",
    "cssls",
    "dockerls",
    "gopls",
    "html",
    "jsonls",
    "marksman",
    "nimls",
    "pyright",
    "rust_analyzer",
    "sumneko_lua",
    "tailwindcss",
    "terraformls",
    "tflint",
    "tsserver",
    "vimls",
    "yamlls",
})

lsp.set_preferences({
    set_lsp_keymaps = { omit = { "K", "<C-k>" } },
})

lsp.configure("sumneko_lua", {
    settings = {
        Lua = {
            workspace = {
                checkThirdParty = false, -- turn off annoying luassert messages
            },
        },
    },
})

M.lsp = lsp

return M
