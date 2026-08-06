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
-- blink.pairs asks its Rust parser whether a delimiter before the cursor is
-- still unmatched, and only opens a fresh pair when it isn't. That parser
-- tracks a stack of distinct opening/closing tokens, so symmetric delimiters
-- (` " $ ' _ *) are never on it and the lookup always answers nil. Typing ` at
-- the end of `foo therefore inserts a whole new pair instead of closing the
-- span, giving `foo``, and <BS> then deletes both delimiters because it removes
-- pairs by shape rather than by who inserted them. Count the delimiters to the
-- left instead: an odd count means the cursor sits inside an unclosed span, so
-- emit a single character to close it.
--
-- The open_or_close hook is implemented and documented upstream but missing
-- from the config validator's field whitelist, so widen the `pairs` schema to a
-- plain table before the config module resolves its defaults.
local pairs_schema = require("blink.pairs.config.mappings")
pairs_schema.pairs[2] = "table"

---Build an `open_or_close` predicate for a symmetric delimiter.
---@param char string The delimiter, which is both the opening and closing text
---@return fun(ctx: blink.pairs.Context): boolean open Whether to insert a pair
local function balanced(char)
  local pattern = vim.pesc(char)
  return function(ctx)
    -- A closer already sits under the cursor; let blink.pairs jump over it
    if ctx:is_after_cursor(char) then
      return true
    end
    local before = ctx:text_before_cursor():gsub("\\.", "")
    local _, count = before:gsub(pattern, "")
    return count % 2 == 0
  end
end

-- Walk the default rule definitions and attach the predicate to every
-- single-character symmetric rule. Opening/closing are derived the same way
-- blink.pairs' own rule.rule_from_def() derives them.
for key, definitions in pairs(pairs_schema.pairs[1]) do
  if type(definitions) == "table" then
    for _, def in ipairs(definitions) do
      local closing = #def == 1 and def[1] or def[2]
      local opening = #def == 2 and def[1] or key
      if opening == closing and #opening == 1 then
        def.open_or_close = balanced(opening)
      end
    end
  end
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

-- agentcomplete.nvim must be called AFTER blink.cmp setup
require("agentcomplete").setup({})
