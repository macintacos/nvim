-- Following: https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTIN_CONFIG.md
local null_ls = require("null-ls")
local actions = null_ls.builtins.code_actions
local diag = null_ls.builtins.diagnostics
local fmt = null_ls.builtins.formatting
local hover = null_ls.builtins.hover
local cmp = null_ls.builtins.completion

null_ls.setup({
    sources = {
        -- Formatters
        fmt.black,
        fmt.fish_indent,
        fmt.gofumpt,
        fmt.goimports,
        fmt.golines,
        fmt.just,
        fmt.nimpretty,
        fmt.prettier.with({
            args = { "--no-prose-wrap" },
        }),
        fmt.ruff,
        fmt.rustfmt,
        fmt.rustywind,
        fmt.shfmt,
        fmt.stylua,
        fmt.taplo,
        fmt.terrafmt,
        fmt.trim_whitespace,
        fmt.yamlfmt,

        -- Diagnostics
        diag.commitlint,
        diag.dotenv_linter,
        diag.eslint,
        diag.fish,
        diag.hadolint,
        diag.luacheck,
        diag.markdownlint,
        diag.mypy,
        diag.ruff,
        diag.shellcheck,
        diag.stylelint,
        diag.vint,
        diag.vulture,
        diag.yamllint,

        -- Hovers
        hover.dictionary,
        hover.printenv,

        -- Actions
        actions.gitsigns,
        actions.refactoring,
        actions.shellcheck,

        -- Completions
        cmp.spell,
    },
})

require("mason-null-ls").setup({
    automatic_installation = true,
    automatic_setup = false,
    ensure_installed = nil,
})
