# branches

`<leader>gb` opens a centered picker over the repo's branches, with a Local section above a
Remote section. Choosing a branch switches to it, or moves you to the worktree that already
has it checked out. The last row creates a new branch from what you type.

## Usage

Type to filter both sections at once, then press `<CR>` on a row. What happens depends on
the row:

| Row | `<CR>` |
| --- | --- |
| The current branch | Closes the picker. |
| Another local branch | `git switch <branch>`. |
| A branch checked out in another worktree | Relaunches Neovim in that worktree, as `<leader>gw` does. |
| A remote branch | `git switch --track <remote>/<branch>`: creates a local branch that tracks it. |
| `Create branch <name>` | `git switch -c <name>`: branches off HEAD and switches to it. |

The create row names its branch after the query. With nothing typed, it asks for a name
and `<CR>` keeps the picker open. Once the query is exactly the name of a local branch, the
row disappears, so `<CR>` switches to that branch instead. A remote branch's name doesn't
hide it.

`<M-p>` swaps the list for the highlighted branch's last 100 commits, and pressing it
again brings the list back. For a branch in another worktree, the preview first says where
that worktree is. On the create row, it shows HEAD's commits, which the new branch starts
from.

## What a row shows

Each row starts with an icon for its kind and the branch's name. Dim columns follow, titled
Upstream, Updated, Author, and Last commit: how many commits the branch is ahead of and
behind its upstream, the age of its last commit, and that commit's author and subject. A
line naming the section, Local or Remote, sits above each section's first row. The top
section's line also carries the column titles, with its name over the branch names. A
lower section's line shows only its name. The top section's line stays at the top of the
window as the list scrolls.

| Icon | Kind |
| --- | --- |
| `󱓏` (purple) | The current branch |
| `󰘬` | A local branch |
| `` | A local branch checked out in another worktree |
| `󰅣` | A remote branch, its `<remote>/` prefix dimmed |
| `󱓊` | The create row |

The Upstream column reads `↑2 ↓1` for two commits ahead and one behind, and `gone` when
the upstream was deleted. It stays blank for a branch level with its upstream or without
one. When it would be blank on every row, the picker leaves it out. The Updated column
gives an age in its largest whole unit, such as `4mo` or `3h`, and reads `now` under a
minute.

A name longer than 40 cells, counting a remote's `<remote>/` prefix, ends in `…`, so the
columns still line up. The preview (`<M-p>`) shows the whole name in its title. An author
longer than 16 cells ends in `…` too, as does a subject wider than the room the window
leaves it.

Each section lists its branches by their last commit, newest first, with the current
branch at the top. The Remote section lists only remote branches you have no local branch
for, so `origin/trunk` doesn't sit beside `trunk`, and it leaves out `origin/HEAD`.

## Switching

A switch refuses while any buffer has unsaved changes, because the buffer would no longer
match the branch's files. Save or discard them, then switch again. Creating a branch
doesn't refuse, because it leaves the files as they are.

Git decides what happens to uncommitted changes. It carries them to the new branch when it
can, and refuses when they would be overwritten. Its message then shows as an error. After
a switch, open buffers reload from disk.

The cursor starts on the branch you checked out before this one, so `<leader>gb<CR>`
switches back to it, as `git switch -` does. Without one, it starts on the newest branch
other than the current one.

## Limitations

- The picker only switches and creates branches. Delete, rename, or push them in lazygit
  (`<leader>gs`).
- Rows don't show whether a branch has a pull request.
- Moving to another worktree needs the fish `nvim` wrapper that
  [`projects`](../projects/) describes. Without it, Neovim quits.
