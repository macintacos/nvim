local lsp_installer = require("nvim-lsp-installer")

-- Cusomized Options
local enhance_server_opts = {
    ["yamlls"] = function(opts)
        opts.settings = {
            format = {
                enable = true
            }
        }
    end,
}

-- Initialize things
lsp_installer.on_server_ready(function(server)
    local opts = {}
    local aerial = require("aerial")

    opts.on_attach = function(client)
        require("lsp_signature").on_attach({
            floating_window_above_cur_line = true,
            handler_opts = {
                border = "single",
            },
            transparency = 1,
        })

        aerial.on_attach(client)
    end

    if server.name == "sumneko_lua" then
        opts.settings = require("lua-dev").setup().settings
    end

    if enhance_server_opts[server.name] then
        enhance_server_opts[server.name](opts)
    end

    server:setup(opts)
end)

-- Mappings
local map = vim.api.nvim_set_keymap
local map_opts = { noremap = true }

map("i", "<M-k>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
map("n", "<C-LeftMouse>", "<Cmd>lua vim.lsp.buf.definition()<CR>", map_opts)
map("n", "[d", "<Cmd>lua vim.diagnostic.goto_prev({ border = 'rounded', max_width = 80})<CR>", map_opts)
map("n", "]d", "<Cmd>lua vim.diagnostic.goto_next({ border = 'rounded', max_width = 80})<CR>", map_opts)
map("n", "g0", "<Cmd>Telescope lsp_document_symbols<CR>", map_opts )
map("n", "g<C-LeftMouse>", "<Cmd>lua vim.lsp.buf.implementation()<CR>", map_opts)
map("n", "gD", "<Cmd>lua vim.lsp.buf.declaration({ border = 'rounded', max_width = 80 })<CR>", map_opts)
map("n", "gW", "<Cmd>Telescope lsp_workspace_symbols<CR>", map_opts)
map("n", "gd", "<Cmd>Telescope lsp_definitions<CR>", map_opts)
map("n", "gh", "<Cmd>lua vim.lsp.buf.hover({ popup_opts = { border = single, max_width = 80 }})<CR>", map_opts)
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
