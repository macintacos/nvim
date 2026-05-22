# gotoline

A small local plugin that exposes a single command, `:GoToLine`, opening a
centered floating popup for jumping to a line in a project file.

## Usage

Run `:GoToLine`. A two-pane modal appears:

- **Prompt** (top): where you type.
- **Results** (below): file list while you search, or a treesitter-highlighted
  file preview once a file is locked in.

The prompt grammar is `(<file-query>:)<line-number>`:

| You type | What happens |
|---|---|
| Letters | Fuzzy-search project files; results below. Basename matches rank above path-only matches. |
| `<C-j>` / `<C-n>` / `<Tab>` | Select next result (wraps). |
| `<C-k>` / `<C-p>` / `<S-Tab>` | Select previous result (wraps). |
| `<CR>` or `:` (with a result selected) | Lock that file; prompt becomes `<file>:` and the results pane switches to a preview. |
| Digits after the lock | Re-anchors the preview at that line. |
| `<BS>` past the `:` | Unlock the file; results return to the file list. |
| `<CR>` (with file + line) | Jump to that file at that line; modal closes. |
| Digits with an empty prompt | Jump to that line in the buffer that was active when the modal opened. |
| `<Esc>` (insert) | Leave insert mode. |
| `<Esc>` (normal) or `q` | Close the modal. |

## Setup

Wired up in `plugin/gotoline.lua`. No configuration is required.

```lua
require("plugins.gotoline").setup({})
vim.api.nvim_create_user_command("GoToLine", function()
  require("plugins.gotoline").open()
end, {})
```

## Project root

Files are listed from the git root, falling back to `cwd`. Listing uses
`rg --files --hidden --glob '!.git'` and is cached per root for the session.

## Highlight groups

Both default to a sensible fallback and can be overridden:

- `GotolineTargetLine` — line highlight on the preview's target line
  (defaults to `Visual`).
- `GotolineSelected` — line highlight on the selected result in the list
  (defaults to `CursorLine`).
