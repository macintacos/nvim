local ext_config = {
    "williamboman/nvim-lsp-installer",
    requires = {
        "neovim/nvim-lspconfig",
    },
    config = function()
        local lspinstaller = require("nvim-lsp-installer")
        local lspconfig = require("lspconfig")

        lspinstaller.setup({})

        local capabilities = vim.lsp.protocol.make_client_capabilities()

        for _, server in ipairs(lspinstaller.get_installed_servers()) do
            local opts = {}
            local aerial = require("aerial")

            if server.name == "sumneko_lua" then
                opts.settings = require("lua-dev").setup().settings
            elseif server.name == "yamlls" then
                opts.settings = {
                    format = {
                        enable = true,
                    },
                }
            end

            lspconfig[server.name].setup({
                settings = opts.settings,
                on_attach = function(client)
                    if server.name == "sumneko_lua" then
                        -- Turn off sumneko_lua trying to format, just let null_ls do it.
                        client.resolved_capabilities.document_formatting = false
                        client.resolved_capabilities.document_range_formatting = false
                    end
                    require("lsp_signature").on_attach({
                        floating_window_above_cur_line = true,
                        handler_opts = {
                            border = "single",
                        },
                        transparency = 1,
                    })

                    aerial.on_attach(client)

                    -- Mappings
                    local map = vim.api.nvim_set_keymap
                    local map_opts = { noremap = true }

                    map("i", "<M-k>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
                    map("n", "<C-LeftMouse>", "<Cmd>lua vim.lsp.buf.definition()<CR>", map_opts)
                    map(
                        "n",
                        "[d",
                        "<Cmd>lua vim.diagnostic.goto_prev({ border = 'rounded', max_width = 80})<CR>",
                        map_opts
                    )
                    map(
                        "n",
                        "]d",
                        "<Cmd>lua vim.diagnostic.goto_next({ border = 'rounded', max_width = 80})<CR>",
                        map_opts
                    )
                    map("n", "g0", "<Cmd>Telescope lsp_document_symbols<CR>", map_opts)
                    map("n", "g<C-LeftMouse>", "<Cmd>lua vim.lsp.buf.implementation()<CR>", map_opts)
                    map(
                        "n",
                        "gD",
                        "<Cmd>lua vim.lsp.buf.declaration({ border = 'rounded', max_width = 80 })<CR>",
                        map_opts
                    )
                    map("n", "gW", "<Cmd>Telescope lsp_workspace_symbols<CR>", map_opts)
                    map("n", "gd", "<Cmd>Telescope lsp_definitions<CR>", map_opts)
                    map(
                        "n",
                        "gh",
                        "<Cmd>lua vim.lsp.buf.hover({ popup_opts = { border = single, max_width = 80 }})<CR>",
                        map_opts
                    )
                    map("n", "gi", "<Cmd>Telescope lsp_implementations<CR>", map_opts)
                    map("n", "gr", "<Cmd>Telescope lsp_references<CR>", map_opts)
                    map("n", "gi", "<Cmd>Telescope lsp_implementations<CR>", map_opts)
                    map("n", "gr", "<Cmd>Telescope lsp_references<CR>", map_opts)

                    -- Icons
                    local signs = {
                        Error = " ",
                        Warn = " ",
                        Hint = " ",
                        Info = " ",
                    }
                    for type, icon in pairs(signs) do
                        local hl = "DiagnosticSign" .. type
                        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
                    end
                end,

                flags = {
                    debounce_text_changes = 150,
                },

                capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities),
            })
        end
    end,
}

return ext_config
