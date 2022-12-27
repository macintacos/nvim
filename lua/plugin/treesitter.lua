-- Top-level config
require("nvim-treesitter.configs").setup({
    ensure_installed = {
        "bash",
        "c",
        "css",
        "dockerfile",
        "fish",
        "go",
        "gomod",
        "hcl",
        "help",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "lua",
        "make",
        "markdown",
        "python",
        "regex",
        "ruby",
        "rust",
        "scss",
        "svelte",
        "typescript",
        "vim",
        "yaml",
        "zig",
    },
    highlight = { enable = true }, -- builtin
    indent = { enable = true }, -- builtin
    matchup = { enable = true }, -- vim-matchup

    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "<A-CR>",
            scope_incremental = "<A-CR>",
            node_incremental = "<Up>",
            node_decremental = "<Down>",
        },
    },
})
