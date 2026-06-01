# pack-tweaks

A small local plugin holding tweaks to Neovim's built-in `vim.pack` plugin manager. This directory is the home for future `vim.pack` UI/behavior adjustments — each lands as its own module wired through `setup()`.

## Current tweaks

### Open a commit/tag in its remote

When `vim.pack.update()` runs, Neovim opens a confirmation buffer (`filetype=nvim-pack`) listing each plugin's pending commits, before/after revisions, and available newer version tags. This tweak adds a buffer-local `<CR>` keymap that opens the line under the cursor in the browser:

| Cursor line | Opens |
|---|---|
| A commit line (`> sha │ subject` or `< sha │ subject`) | `<source>/commit/<sha>` |
| A `Revision before/after:` (or `Revision:`) line | `<source>/commit/<sha>` |
| An available-version line (`• v1.2.0`) | `<source>/releases/tag/v1.2.0` |
| Anything else (headers, blanks, `Source:`) | nothing (no-op) |

The remote URL is resolved from the plugin's `Source:` line in the same section, so it works even for plugins shown as `(not active)`. URLs assume a GitHub-style host (every source in this config is `github.com`). Opening uses the built-in `vim.ui.open`.

## Setup

Wired up in `plugin/pack-tweaks.lua`. No configuration is required — `setup()` registers a single `FileType nvim-pack` autocmd that attaches each tweak's keymaps to the confirmation buffer.

## Tests

`tests/pack-tweaks/open_commit_spec.lua` covers the pure helpers (`_parse_target`, `_find_source`, `_build_url`). Run with `mise run test`.
