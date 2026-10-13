# scratch

Per-project scratch files in `<cwd>/.tmp/scratch/`. The first open creates
`scratch.md` without asking. Once one exists, opening shows a picker: `+ New scratch
file` on top, then every file in the directory, most recently modified first. The file
under the cursor previews beside the list, or above it in a narrow editor — the
[mini-pickers](../mini-pickers/) side preview.

New asks for a name. `api-notes` becomes `api-notes.md`, a name with its own extension
keeps it, and an empty name takes the next free `scratch.md`, `scratch-2.md`, … A name
that already exists opens that file. `<Esc>` in the picker or at the prompt does
nothing.

## Keymaps

| Key                            | Action                                        |
| ------------------------------ | --------------------------------------------- |
| `<leader>wt`, `<leader>ft`, `<leader>ps` | Pick a scratch file and open it in the current window |
| `<leader>wT`, `<leader>pS`     | Pick one and open it in a float covering 80% of the editor |

All keymaps live in [`plugin/which-key.lua`](../../../plugin/which-key.lua).

## API

```lua
require("plugins.scratch").open()  -- edit in the current window
require("plugins.scratch").float() -- edit in a centered float
```

The float is an ordinary window over a real file buffer, so `:w` saves and `:q`
(or `<C-w>q`) closes it. Picking a file a float already shows focuses that float.

## Notes

The pick runs after the picker has closed, so the file opens in the window the picker
was opened from, and a float hands focus back to that window when it closes.

`.tmp/` is not gitignored by this plugin — add it to the project's `.gitignore`
if scratch files shouldn't be committed. Only files in `.tmp/scratch/` are listed;
move a file there to list it.
