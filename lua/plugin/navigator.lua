require("navigator").setup({
    default_mapping = false,
    lsp_installer = true,
    on_attach = function(client, bufnr)
        if client.resolved_capabilities.document_formatting then
            vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
        end
    end,
    keymaps = {
        -- Other maps are in whichkey config or down below
        -- {key = "<c-k>", func = "signature_help()"},
        -- {key = "<Leader>gT", func = "require('navigator.treesitter').bufs_ts()"},
        -- {key = "<Space>ca", mode = "n", func = "require('navigator.codeAction').code_action()"},
        -- {key = "<Space>cA", mode = "v", func = "range_code_action()"},
        -- {key = "<Leader>re", func = "rename()"},
        -- {key = "<Space>rn", func = "require('navigator.rename').rename()"},
        -- {key = "<Leader>gi", func = "incoming_calls()"},
        -- {key = "<Leader>go", func = "outgoing_calls()"},
        -- {key = "<Space>D", func = "type_definition()"},
        -- {key = "<Leader>dt", func = "require('navigator.diagnostics').toggle_diagnostics()"},
        -- {key = "<Leader>k", func = "require('navigator.dochighlight').hi_symbol()"},
        -- {key = '<Space>wa', func = 'add_workspace_folder()'},
        -- {key = '<Space>wr', func = 'remove_workspace_folder()'},
        -- {key = '<Space>ff', func = 'formatting()', mode='n'},
        -- {key = '<Space>ff', func = 'range_formatting()', mode='v'},
        -- {key = '<Space>wl', func = 'print(vim.inspect(vim.lsp.buf.list_workspace_folders()))'},
        -- {key = "<Space>la", mode = "n", func = "require('navigator.codelens').run_action()"},
    },
})

local map = vim.api.nvim_set_keymap
local map_opts = { noremap = true, silent = true }

map("i", "<M-k>", "<Cmd>lua vim.lsp.buf.signature_help()<CR>", map_opts)
map("n", "<C-LeftMouse>", "<Cmd>lua vim.lsp.buf.definition()<CR>", map_opts)
map("n", "[d", "<Cmd>lua vim.lsp.diagnostic.goto_prev({ border = 'rounded', max_width = 80})<CR>", map_opts)
map("n", "[r", "<Cmd>lua require('navigator.treesitter').goto_previous_usage()<CR>", map_opts)
map("n", "]d", "<Cmd>lua vim.lsp.diagnostic.goto_next({ border = 'rounded', max_width = 80})<CR>", map_opts)
map("n", "]r", "<Cmd>lua require('navigator.treesitter').goto_next_usage()<CR>", map_opts)
map("n", "g0", "<Cmd>Telescope lsp_document_symbols<CR>", map_opts)
map("n", "g<C-LeftMouse>", "<Cmd>lua vim.lsp.buf.implementation()<CR>", map_opts)
map("n", "gD", "<Cmd>lua vim.lsp.buf.declaration({ border = 'rounded', max_width = 80 })<CR>", map_opts)
map("n", "gT", "<Cmd>lua require('navigator.treesitter').buf_ts()<CR>", map_opts)
map("n", "gW", "<Cmd>Telescope lsp_workspace_symbols<CR>", map_opts)
map("n", "gd", "<Cmd>lua require('navigator.definition').definition()<CR>", map_opts)
map("n", "gh", "<Cmd>lua vim.lsp.buf.hover({ popup_opts = { border = single, max_width = 80 }})<CR>", map_opts)
map("n", "gi", "<Cmd>Telescope lsp_implementations<CR>", map_opts)
map("n", "gp", "<Cmd>lua require('navigator.treesitter').definition_preview()<CR>", map_opts)
map("n", "gr", "<Cmd>Telescope lsp_references<CR>", map_opts)
