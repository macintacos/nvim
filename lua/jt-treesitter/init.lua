require("nvim-treesitter.configs").setup {
    ensure_installed = "maintained",
    highlight = {enable = true},
    indent = {enable = true},
    -- refactor = {
    --     highlight_definitions = {enable = true},
    --     highlight_current_scope = {enable = true},
    --     smart_rename = {enable = true, keymaps = {smart_rename = "grr"}},
    --     navigation = {
    --         enable = true,
    --         keymaps = {
    --             goto_definition = "gd",
    --             list_definitions = "gD",
    --             list_definitions_toc = "gO",
    --             goto_next_usage = "<C-n>",
    --             goto_previous_usage = "<C-p>"
    --         }
    --     }
    -- }
}

-- We set up folding here because.... reasons. Not sure how I feel about it, maybe one day figure out how to enable conditionally?
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
