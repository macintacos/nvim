# nvim

![Two screenshots on a loop: Neovim's start screen, listing a resumable session, project actions and a plugin-update count; and the config editing itself, with a fuzzy file picker open over init.lua, the which-key leader spec, and the list of mini.nvim modules.](./assets/preview.gif)

This is where the work happens now. It used to run on lazy.nvim, and this README used to
open by apologising for itself and sending you to VSCode for anything serious. Neither is
true any more.

It's [a repo of its own](https://github.com/macintacos/nvim), pulled into
[my dotfiles](https://github.com/macintacos/dotfiles) as a chezmoi external so it travels
under its own history. [Ghostty](https://ghostty.org/) is the terminal;
[herdr](https://herdr.dev), the agent multiplexer it all runs inside.

## What's in the screenshots

- **The start screen** — [mini.starter](https://github.com/nvim-mini/mini.starter),
  assembled here: this project's own session pinned above everything, the few things worth
  reaching for before a file is open, every other session most-recently-written first, and
  a count of plugins that have moved since the lock file was written.
- **The config editing itself** — [mini.pick](https://github.com/nvim-mini/mini.pick) over
  the project, the which-key spec that draws the leader menu, and the mini module list in
  `plugin/mini.lua`.

## The shape of it

**No plugin manager.** [`vim.pack`](https://neovim.io/doc/user/pack.html) ships with
Neovim 0.12 and is enough. Each plugin gets a file under `plugin/` — or a family does,
which is why `mini.lua` holds the whole mini set — and Neovim sources them itself after
`init.lua`. Versions land in `nvim-pack-lock.json`. Loading is one of three tiers:
eager, deferred behind a `vim.schedule`, or lazy behind a stub command or keymap that
`packadd`s the real thing on first use.

**[mini.nvim](https://github.com/nvim-mini/mini.nvim) is the spine.** The picker, the file
explorer, the start screen, sessions, the statusline, notifications and `vim.ui.input` are
all mini — sixteen modules pinned in `plugin/mini.lua`, fifteen on `stable` and one
tracking `main` until it tags. [snacks.nvim](https://github.com/folke/snacks.nvim) covers
what mini doesn't: indent guides, scope, smooth scroll, the statuscolumn, the terminal,
lazygit, zen mode, image rendering, and the big-file and quickfile guards. Its notifier,
input and `vim.ui.select` are switched off, each with a comment at both ends naming the
mini module that took the job.

**Local plugins are first-class.** Eight of them under `lua/plugins/`, each with a README
and specs in `tests/`. They exist because nothing upstream did the thing: a project
switcher that relaunches Neovim through the fish `nvim` wrapper so the shell ends up in
the new directory too, an update checker that runs `git ls-remote` in libuv's thread pool
and feeds a spinner into the statusline, a picker that points a plugin's spec at an open
PR's branch so it can be smoke-tested live.

**It's maintained like a project.** 21 [plenary](https://github.com/nvim-lua/plenary.nvim)
spec files, selene and stylua over the Lua, and [hk](https://hk.jdx.dev/) on the hooks:
format and lint on commit, the test suite on push. [mise](https://mise.jdx.dev/) pins
every tool that does any of it.

## Local plugins

| Plugin | What it does |
| --- | --- |
| [`blink-omni`](lua/plugins/blink-omni/) | Bridges a buffer's `omnifunc` into the blink.cmp menu — how Ghostty's config options reach completion. |
| [`ftchooser`](lua/plugins/ftchooser/) | `<leader>fl` picks a buffer's filetype from human names; the choice is remembered per file across restarts. |
| [`gotoline`](lua/plugins/gotoline/) | `:GoToLine` — one floating prompt that fuzzy-finds a project file, previews it, then jumps to a line in it. |
| [`mini-pickers`](lua/plugins/mini-pickers/) | Replacement mini.pick registry entries: document symbols as a real tree, thinned workspace symbols, per-line blame, and an `rg` invocation whose flags are ours. |
| [`pack-pr`](lua/plugins/pack-pr/) | `:PackPR` — pick an open PR across managed repos and point that plugin's `vim.pack` spec at its branch, with a one-key path back. |
| [`pack-tweaks`](lua/plugins/pack-tweaks/) | `<CR>` on a line in the `vim.pack` update buffer opens that commit or tag in the browser. |
| [`projects`](lua/plugins/projects/) | `<leader>pp` — a [zoxide](https://github.com/ajeetdsouza/zoxide) picker that relaunches Neovim in the directory you choose, session and all. |
| [`uv-scripts`](lua/plugins/uv-scripts/) | Filetype detection and a `ty` client pointed at the environment [uv](https://docs.astral.sh/uv/guides/scripts/) builds for a PEP 723 single-file script. |

## Working on it

```sh
mise run setup      # install the pinned tools, register the git hooks
mise run preflight  # lint + test (the pre-push hook runs the tests only)
mise run format     # stylua, rumdl, yamlfmt, taplo, pkl, shfmt
mise run test       # the plenary suite
mise run install    # update plugins via vim.pack
```

None of this is meant to be installed by anyone else — there's no bootstrap, no attempt at
portability, and a few things quietly assume my machine. Take whatever looks useful.
