# blink-omni

A [blink.cmp](https://github.com/Saghen/blink.cmp) completion source that bridges the current buffer's `omnifunc` into the completion menu.

## What it does

Many filetype plugins set an `&omnifunc` (normally reached with `<C-x><C-o>`). This source calls that function the way the editor itself does — first in findstart mode to locate the base column, then in results mode with the typed prefix — and surfaces its suggestions as ordinary blink items.

It normalizes the three shapes an omnifunc may return:

- a list of strings
- a list of complete-item dicts (`word`, `abbr`, `menu`, `info`, `kind`)
- the `{ words = {...} }` dict form

Mapping: `abbr` (or `word`) → label, `word` → insert text, `menu` → detail, `info` → documentation, `kind` letter → LSP kind. Each item's replacement range is anchored at the column the omnifunc reported.

## Where it's used

Wired in for Ghostty config files (see `plugin/ghostty.lua` and `plugin/blink.lua`), whose `ftplugin` sets `omnifunc=syntaxcomplete#Complete`, so Ghostty's config options appear in the blink popup. The source is generic, though — it works for any buffer with an `omnifunc`.

## Setup

No `setup()` needed. Register it as a blink.cmp source for the relevant filetype:

```lua
require("blink.cmp").setup({
  sources = {
    per_filetype = {
      ghostty = { "omni", "path", "buffer" },
    },
    providers = {
      omni = {
        name = "Omni",
        module = "plugins.blink-omni",
      },
    },
  },
})
```

`<C-x><C-o>` still works independently; this only adds the same suggestions to the normal completion popup.
