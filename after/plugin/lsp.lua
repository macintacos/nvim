--[[ TODOS

TODO: Add some languages to the default set that are downloaded by default (if possible with lsp-zero)

--]]

require("neodev").setup()

-- Mason Settings
require('mason.settings').set({
  ui = {
    border = 'rounded'
  }
})

local lsp = require('lsp-zero')

-- LSP-specific settings
lsp.on_attach(function(client, bufnr)
    -- Mappings
    local bind = vim.keymap.set

    bind('n', "gh", "<Cmd>lua vim.lsp.buf.hover()<CR>", { noremap = true, silent = true })
end)

lsp.preset('recommended')

-- nvim-cmp settings
local cmp          = require('cmp')
local cmp_mappings = lsp.defaults.cmp_mappings()

-- For mapping <CR> {{{
-- If you want insert `(` after select function or method item
local cmp_autopairs = require("nvim-autopairs.completion.cmp")
cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
-- }}}

-- For SuperTab-like completion {{{
local has_words_before = function()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local feedkey = function(key, mode)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end
-- }}}

cmp_mappings["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" })
cmp_mappings["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" })
cmp_mappings["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" })
cmp_mappings["<C-y>"] = cmp.config.disable -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
cmp_mappings["<C-e>"] = cmp.mapping({
    i = cmp.mapping.abort(),
    c = cmp.mapping.close(),
})
cmp_mappings["<C-k>"] = cmp.config.disable

cmp_mappings["<Tab>"] = cmp.mapping(function(fallback)
    if cmp.visible() then
        cmp.select_next_item()

    elseif has_words_before() then
        feedkey("<Plug>(Tabout)", "")

    else
        fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
    end
end, { "i", "s" })

cmp_mappings["<S-Tab>"] = cmp.mapping(function()
    if cmp.visible() then
        cmp.select_prev_item()
    elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        feedkey("<Plug>(vsnip-jump-prev)", "")
    end
end, { "i", "s" })

local lspkind = require("lspkind")

lsp.setup_nvim_cmp({
    mapping = cmp_mappings,
    completion = {
        completeopt = "menu,menuone,noselect",
    },
    sources = {
        { name = 'path' },
        { name = 'nvim_lsp', keyword_length = 3 },
        { name = 'buffer', keyword_length = 3 },
        { name = 'luasnip', keyword_length = 2 },
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

lsp.setup()
