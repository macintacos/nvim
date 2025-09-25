-- github.com/Saghen/blink.pairs
-- Pairing parens and other things

---@module "lazy"
---@type LazySpec
return {
  "Saghen/blink.pairs",
  version = "*",
  dependencies = "Saghen/blink.download",

  --- @module 'blink.pairs'
  --- @type blink.pairs.Config
  opts = {
    mappings = {
      enabled = true,
      disabled_filetypes = {},
    },
    highlights = {
      enabled = true,
      groups = {},

      -- highlights matching pairs under the cursor
      matchparen = {
        enabled = true,
        group = "BlinkPairsMatchParen",
      },
    },
    debug = false,
  },
}
