require("navigator").setup({
    default_mapping = false,
    lsp_installer = true,
    on_attach = function(client, bufnr)
        if client.server_capabilities.document_formatting then
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
