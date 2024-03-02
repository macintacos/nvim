require("nvim-treesitter.configs").setup({
    -- A list of parser names, or "all"
    ensure_installed = {
        "astro",
        "c",
        "css",
        "help",
        "javascript",
        "jsonnet",
        "lua",
        "rust",
        "tsx",
        "typescript",
        "vim",
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    matchup = {
        enable = true,
    },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false,
    },

    -- https://github.com/HiPhish/nvim-ts-rainbow2
    rainbow = {
        enable = true,
        query = "rainbow-parens",
        strategy = require("ts-rainbow.strategy.global"),
    },
})
