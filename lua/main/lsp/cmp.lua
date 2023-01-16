-- nvim-cmp settings: https://github.com/hrsh7th/nvim-cmp

local cmp = require("cmp")
local lsp = require("main.lsp.zero").lsp
local lspkind = require("lspkind") -- for formatting the completion window

-- For mapping <CR> {{{
-- If you want insert `(` after select function or method item
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
-- }}}

local cmp_mappings = lsp.defaults.cmp_mappings({

    ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
    ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
    ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
    ["<C-y>"] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ["<C-e>"] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
    }),
    ["<C-k>"] = cmp.config.disable,

    ["<Tab>"] = cmp.mapping(function(fallback)
        -- Tab will only
        if cmp.visible() then
            cmp.select_next_item()
        elseif require("luasnip").expand_or_jumpable() then
            require("luasnip").expand_or_jump()
        else
            fallback()
        end
    end, { "i", "s" }),

    ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
            cmp.select_prev_item()
        elseif require("luasnip").jumpable(-1) then
            require("luasnip").jump(-1)
        else
            fallback()
        end
    end, { "i", "s" }),
})

-- Use the lsp to setup nvim-cmp using the new settings
lsp.setup_nvim_cmp({
    mapping = cmp_mappings,
    completion = {
        completeopt = "menu,menuone,noinsert,noselect",
    },
    sources = {
        { name = "path" },
        { name = "nvim_lsp", keyword_length = 3 },
        { name = "buffer", keyword_length = 3 },
        { name = "luasnip", keyword_length = 2 },
        { name = "fish" },
        { name = "treesitter" },
    },
    formatting = {
        format = lspkind.cmp_format({
            with_text = false,
            maxwidth = 50,
            menu = {
                buffer = "[Buffer]",
                nvim_lsp = "[LSP]",
                luasnip = "[LuaSnip]",
                nvim_lua = "[Lua]",
                latex_symbols = "[Latex]",
                path = "[Path]",
                look = "[Look]",
                treesitter = "[ts]",
            },
        }),
    },
})

-- Overrides for specific filetypes
cmp.setup.filetype({ "markdown", "txt" }, {
    sources = {
        {
            name = "look",
            keyword_length = 2,
            option = {
                convert_case = true,
                loud = true,
            },
        },
        { name = "emoji", insert = true },
    },
})
