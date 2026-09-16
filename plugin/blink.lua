-- github.com/Saghen/blink.cmp + blink.pairs
-- Completion engine with auto-bracket pairing
vim.pack.add({
  { src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("1.x") },
  "https://github.com/Saghen/blink.pairs",
  "https://github.com/Saghen/blink.lib",
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
    list = { selection = { auto_insert = false, preselect = false } },
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
    -- With an item selected, <Esc> only cancels the completion. With the menu
    -- merely open, it cancels and falls through so a single press also leaves
    -- insert mode.
    ["<Esc>"] = {
      function(cmp)
        if cmp.get_selected_item() then
          return cmp.cancel()
        end
        cmp.hide()
      end,
      "fallback",
    },
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
local pairs_schema = require("blink.pairs.config.mappings")
local blink_pairs = require("plugins.blink-pairs")

-- Walk the default rule definitions and attach the parity predicate to every
-- single-character symmetric rule. Opening/closing are derived the same way
-- blink.pairs' own rule.rule_from_def() derives them.
for key, definitions in pairs(pairs_schema.pairs[1]) do
  if type(definitions) == "table" then
    for _, def in ipairs(definitions) do
      local closing = #def == 1 and def[1] or def[2]
      local opening = #def == 2 and def[1] or key
      if opening == closing and #opening == 1 then
        def.open_or_close = blink_pairs.balanced(opening)
      end
    end
  end
end

-- Markdown emphasis rules bring their own span-aware parity predicate, so they
-- register after the walk instead of inheriting `balanced` from it.
for key, rule in pairs(blink_pairs.md_rules) do
  local definitions = pairs_schema.pairs[1][key] or {}
  table.insert(definitions, rule)
  pairs_schema.pairs[1][key] = definitions
end

require("blink.pairs").setup({
  mappings = { enabled = true, disabled_filetypes = {} },
  highlights = {
    enabled = true,
    groups = {},
    matchparen = { enabled = true, group = "BlinkPairsMatchParen" },
  },
  debug = false,
})

-- Markdown emphasis rules must bypass the engine's Rust-parser stage when
-- opening/closing (see plugins.blink-pairs); every other rule keeps the
-- original handler.
local ops = require("blink.pairs.mappings.ops")
ops.open_or_close_pair = blink_pairs.wrap_open_or_close(ops.open_or_close_pair)

-- agentcomplete.nvim must be called AFTER blink.cmp setup
require("agentcomplete").setup({ context = { stacked = "above" } })
