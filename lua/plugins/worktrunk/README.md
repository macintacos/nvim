# worktrunk

[worktrunk](https://worktrunk.dev) (`wt`) commands under `<leader>gw`. Whatever leaves the
shell in another worktree relaunches Neovim there, the same way [`projects`](../projects/)
does, so that worktree's session reopens and your shell ends up there when you quit.

## Usage

| Key | What it does |
| --- | --- |
| `<leader>gwt` | Opens the fish worktree picker (the shell's `<C-t>`) in a float, with all its keys: switch, `alt-n` new, `alt-b` new off row, `alt-x` remove, `alt-p` prune merged, `alt-o` PR. |
| `<leader>gw-` | `wt switch -`: the previous worktree. |
| `<leader>gwm` | `wt switch ^`: the default branch's worktree. |
| `<leader>gwo` | Picks another worktree and opens this file's copy from it in a vertical split. |
| `<leader>gwd` | Same, but diffs the two. |
| `<leader>gwx` | `wt remove` on this worktree, after a confirmation. |
| `<leader>gwM` | `wt merge` this branch into the default branch, after a confirmation. |

`<leader>gwx` and `<leader>gwM` refuse while any file has unsaved changes, because the
worktree those changes belong to is about to be removed.

## How it works

Every `wt` command runs in a terminal float through an interactive `fish -i -c`. Only
there are `__wt_pick` and wt's `wt` wrapper, which is what changes the shell's directory,
defined. After the command, fish writes `pwd -P` to `$NVIM_WT_LANDED`. If that differs
from Neovim's cwd, the float closes and `require("plugins.projects").switch()` relaunches
Neovim there. Otherwise the float closes, unless the command left output on screen, such
as a refusal from `wt`. In that case it stays open until you press a key.

If the relaunch's `:confirm qall` is cancelled, or fails, after `wt` has removed the
worktree Neovim was in, a warning says so. Save anything unsaved elsewhere, then quit.
Any other failed relaunch, such as a save that errors, reports its error.
`wt remove` parks the worktree under `.git/wt/trash/` before deleting it, so
`plugin/mini/sessions.lua` writes no session for a cwd inside `.git` or one that's gone.

The picker is `__wt_pick` from `~/.config/fish/user/worktrunk.fish` (managed by chezmoi),
reused as it is. Neovim depends on its name, on its being loaded in interactive shells,
and on its leaving the shell where `wt` moved it. A comment there says the same.

## Limitations

- Relaunching needs the fish `nvim` wrapper that [`projects`](../projects/) describes.
  Without it, a switch just quits Neovim.
- `<leader>gwo`/`<leader>gwd` use the same path relative to the worktree root, so a file
  renamed on the other branch isn't found.
