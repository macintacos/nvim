-- github.com/Saghen/blink.cmp + blink.pairs
-- Completion engine with auto-bracket pairing
vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.x") },
  { src = "https://github.com/Saghen/blink.pairs", version = vim.version.range("0.x") },
  "https://github.com/Saghen/blink.download",
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
      markdown = { "lazydev", "lsp", "path", "agentcomplete" },
      ghostty = { "omni", "path", "buffer" },
    },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
      omni = {
        name = "Omni",
        module = "plugins.blink-omni",
      },
      agentcomplete = {
        name = "agentcomplete",
        module = "agentcomplete.backends.blink",
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
  },
})

-- blink.pairs v0.6+ requires its native library before setup(), else it errors
-- from a UIEnter autocmd. blink.download builds it by running cargo in the plugin
-- dir and then looking for the artifact under <plugin>/target/release/. Our global
-- ~/.cargo/config.toml redirects all cargo output to ~/.cache/cargo-target, so the
-- build lands there and the loader never finds it. Force CARGO_TARGET_DIR back
-- in-tree for just this build (env var overrides config.toml), then restore it so
-- the global setting governs everything else. build() short-circuits once the lib
-- is compiled, so cargo only runs on first install or after an update.
local pairs_root = vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/opt/blink.pairs", false, true)[1]
local saved_cargo_target = vim.env.CARGO_TARGET_DIR
vim.env.CARGO_TARGET_DIR = pairs_root .. "/target"
require("blink.pairs").build():pwait(120000)
vim.env.CARGO_TARGET_DIR = saved_cargo_target
require("blink.pairs").setup({
  mappings = { enabled = true, disabled_filetypes = {} },
  highlights = {
    enabled = true,
    groups = {},
    matchparen = { enabled = true, group = "BlinkPairsMatchParen" },
  },
  debug = false,
})

-- agentcomplete.nvim must be called AFTER blink.cmp setup
require("agentcomplete").setup({})
