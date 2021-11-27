-- Top-level config
require("nvim-treesitter.configs").setup {
    ensure_installed = "maintained", -- builtin
    highlight = {enable = true}, -- builtin
    indent = {enable = true}, -- builtin
    matchup = {enable = true}, -- vim-matchup
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "<A-CR>",
            scope_incremental = "<A-CR>",
            node_incremental = "<Up>",
            node_decremental = "<Down>",
        }
    }
}

-- We set up folding here because.... reasons. Not sure how I feel about it, maybe one day figure out how to enable conditionally?
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
