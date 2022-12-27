-- Ref: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
local null_ls = require("null-ls")

local sources = {
    -- Formatters
    null_ls.builtins.formatting.black,
    null_ls.builtins.formatting.fish_indent,
    null_ls.builtins.formatting.gofumpt,
    null_ls.builtins.formatting.goimports,
    null_ls.builtins.formatting.isort,
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.shfmt,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.terraform_fmt,

    -- Actions
    null_ls.builtins.code_actions.eslint,
    null_ls.builtins.code_actions.gitsigns,
    null_ls.builtins.code_actions.refactoring,
    null_ls.builtins.code_actions.shellcheck,

    -- Diagnostics
    null_ls.builtins.diagnostics.eslint,
    null_ls.builtins.diagnostics.luacheck.with({
        extra_args = { "--globals", "vim" },
    }),
    null_ls.builtins.diagnostics.pylint,
    null_ls.builtins.diagnostics.shellcheck,
    null_ls.builtins.diagnostics.stylelint,
    null_ls.builtins.diagnostics.vint,
    null_ls.builtins.diagnostics.yamllint,
}

null_ls.setup({
    sources = sources,
    on_attach = function(client)
        if client.server_capabilities.document_formatting then
            vim.cmd([[
            augroup LspFormatting
                autocmd! * <buffer>
                autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting()
            augroup END
            ]])
        end
    end,
})