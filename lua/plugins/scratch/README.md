# scratch

A per-project scratch file at `<cwd>/.tmp/scratch.md`. The directory and the file
are created on first use.

## Keymaps

| Key                            | Action                                        |
| ------------------------------ | --------------------------------------------- |
| `<leader>wt`, `<leader>ft`, `<leader>ps` | Open the scratch file in the current window |
| `<leader>wT`, `<leader>pS`     | Open it in a float covering 80% of the editor |

All keymaps live in [`plugin/which-key.lua`](../../../plugin/which-key.lua).

## API

```lua
require("plugins.scratch").open()  -- edit in the current window
require("plugins.scratch").float() -- edit in a centered float
```

The float is an ordinary window over a real file buffer, so `:w` saves and `:q`
(or `<C-w>q`) closes it.

## Notes

`.tmp/` is not gitignored by this plugin — add it to the project's `.gitignore`
if the scratch file shouldn't be committed.
