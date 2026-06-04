-- github.com/Saghen/blink.cmp + blink.pairs
-- Completion engine with auto-bracket pairing
vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.x") },
  { src = "https://github.com/Saghen/blink.pairs", version = vim.version.range("0.x") },
  "https://github.com/Saghen/blink.download",
})

require("plugins.blink-markdown-refs").setup({
  paths = {
    "/Users/juliantorres/GitLocal/Play",
    "~/.local/share/",
  },
})

require("blink.cmp").setup({
  enabled = function()
    if vim.b.gotoline_prompt then
      return false
    end
    return vim.bo.filetype ~= "minifiles"
  end,
  fuzzy = { implementation = "prefer_rust_with_warning" },
  appearance = { nerd_font_variant = "mono" },
  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    per_filetype = {
      markdown = { "markdown-refs", "lazydev", "lsp", "path" },
    },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
      ["markdown-refs"] = {
        name = "MarkdownRefs",
        module = "plugins.blink-markdown-refs",
        score_offset = 200,
        async = true,
        timeout_ms = 3000,
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
    list = { selection = { auto_insert = false, preselect = true } },
    accept = { auto_brackets = { enabled = true } },
    menu = { border = "rounded", draw = { treesitter = { "lsp" } } },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      window = { border = "rounded" },
    },
    ghost_text = { enabled = vim.g.ai_cmp },
  },
  keymap = {
    preset = "enter",
    ["<Tab>"] = { "select_next", "fallback" },
    ["<S-Tab>"] = { "select_prev", "fallback" },
    -- Accept completion but strip the leading @ (for markdown-refs source)
    ["<S-CR>"] = {
      function(cmp)
        vim.b.blink_md_refs_strip_at = true
        return cmp.accept()
      end,
      "fallback",
    },
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
