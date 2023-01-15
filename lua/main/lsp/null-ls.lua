-- From: https://github.com/VonHeikemen/lsp-zero.nvim/blob/2a90604fcbf4bee9e3407a8ee1b224bb2cbb6563/advance-usage.md?plain=1#L420

local null_ls = require("null-ls")
local mason_null_ls = require("mason-null-ls")

mason_null_ls.setup({
    automatic_installation = false,
    automatic_setup = true,

    ensure_installed = {
        "black",
        "commitlint",
        "dictionary",
        "dotenv_linter",
        "eslint",
        "fish",
        "fish_indent",
        "gitsigns",
        "gofumpt",
        "goimports",
        "golines",
        "hadolint",
        "isort",
        "isort",
        "jq",
        "just",
        "luacheck",
        "markdownlint",
        "mypy",
        "nimpretty",
        "prettier",
        "printenv",
        "pydocstyle",
        "pylint",
        "refactoring",
        "remark",
        "rustfmt",
        "rustywind",
        "shellcheck",
        "shellharden",
        "shfmt",
        "spell",
        "stylelint",
        "stylua",
        "taplo",
        "terrafmt",
        "terraform_fmt",
        "trim_whitespace",
        "vint",
        "vulture",
        "yamlfmt",
        "yamllint",
    },
})

null_ls.setup()
mason_null_ls.setup_handlers({})
