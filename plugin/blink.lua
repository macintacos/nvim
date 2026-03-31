-- github.com/Saghen/blink.cmp + blink.pairs
-- Completion engine with auto-bracket pairing
vim.pack.add({
  "https://github.com/Saghen/blink.cmp",
  "https://github.com/Saghen/blink.pairs",
  "https://github.com/Saghen/blink.download",
})

require("blink.cmp").setup({
  fuzzy = { implementation = "prefer_rust_with_warning" },
  appearance = { nerd_font_variant = "mono" },
  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
  cmdline = {
    enabled = true,
    keymap = { preset = "cmdline" },
    completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function(_ctx)
          return vim.fn.getcmdtype() == ":"
        end,
      },
      ghost_text = { enabled = true },
    },
  },
  completion = {
    list = { selection = { auto_insert = false, preselect = false } },
    accept = { auto_brackets = { enabled = true } },
    menu = { draw = { treesitter = { "lsp" } } },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
    ghost_text = { enabled = vim.g.ai_cmp },
  },
  keymap = {
    preset = "enter",
    ["<Tab>"] = { "select_next", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },
  },
})

require("blink.pairs").setup({
  mappings = { enabled = true, disabled_filetypes = {} },
  highlights = {
    enabled = true,
    groups = {},
    matchparen = { enabled = true, group = "BlinkPairsMatchParen" },
  },
  debug = false,
})
