# ftchooser

Pick the current buffer's filetype from a Snacks picker of human-friendly names.
The choice is remembered per file and re-applied on every restart.

## Usage

- `<leader>fl` — open the picker. Navigate with `j`/`k` (or type to filter),
  `<CR>` to set, `q`/`<Esc>` to dismiss. The `●` marks the buffer's current
  filetype.

Picking a filetype sets it on the buffer (which in turn drives LSP, treesitter,
conform, and nvim-lint, since those key off filetype) and records
`<absolute path> -> <filetype>` in the store.

## Persistence

Overrides are stored as JSON at `stdpath("state")/ftchooser.json`
(`~/.local/state/nvim/ftchooser.json`). A `BufReadPost` autocmd re-applies a
remembered filetype after Neovim's built-in detection, so your choice wins next
time you open the file.

## Extending

Add a `{ "Label", "filetype" }` line to `M.filetypes` in `init.lua`.

## Limitations

- Overrides key on absolute path; moving/renaming a file orphans its entry (no
  garbage collection).
- No "reset to auto-detected" action yet — re-pick the natural filetype to
  effectively clear an override.
- Reapply runs on `BufReadPost`; a plugin that sets filetype even later could
  win over the remembered value.
