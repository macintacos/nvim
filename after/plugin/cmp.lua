local cmp = require("cmp")

cmp.setup({
    sources = cmp.config.sources({
        { name = "nvim_lua" },
        { name = "treesitter" },
        { name = "buffer" },
        { name = "bufname" },
        { name = "async_path" },
        { name = "git" },
        { name = "fish" },
        { name = "cmp_csv" },
    }),
})

cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = "path" },
        { name = "cmdline_history" },
        { name = "cmdline" },
    }),
    matching = { disallow_symbol_nonprefix_matching = false },
})

require("cmp_git").setup()
