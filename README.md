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

**Local plugins are first-class.** Ten of them under `lua/plugins/`, each with specs
in `tests/`. They exist because nothing upstream did the thing: a project
switcher that relaunches Neovim through the fish `nvim` wrapper so the shell ends up in
the new directory too, an update checker that runs `git ls-remote` in libuv's thread pool
and feeds a spinner into the statusline, a picker that points a plugin's spec at an open
PR's branch so it can be smoke-tested live.

**It's maintained like a project.** A [plenary](https://github.com/nvim-lua/plenary.nvim)
spec suite with a startup smoke test and luacov coverage, selene and stylua over the Lua,
lua-language-server type-checking it, and [hk](https://hk.jdx.dev/) on the hooks: format
and lint on commit, the type check and test suite on push. [mise](https://mise.jdx.dev/)
pins every tool that does any of it.

## Local plugins

| Plugin | What it does |
| --- | --- |
| [`blink-omni`](lua/plugins/blink-omni/) | Bridges a buffer's `omnifunc` into the blink.cmp menu — how Ghostty's config options reach completion. |
| [`blink-pairs`](lua/plugins/blink-pairs/) | blink.pairs rules for Markdown emphasis that stay out of inline code spans, and the parity check that decides when a symmetric delimiter opens a new pair. |
| [`ftchooser`](lua/plugins/ftchooser/) | `<leader>fl` picks a buffer's filetype from human names; the choice is remembered per file across restarts. |
| [`gotoline`](lua/plugins/gotoline/) | `:GoToLine` — one floating prompt that fuzzy-finds a project file, previews it, then jumps to a line in it. |
| [`mini-pickers`](lua/plugins/mini-pickers/) | Replacement mini.pick registry entries: document symbols as a real tree, thinned workspace symbols, per-line blame, and an `rg` invocation whose flags are ours. |
| [`pack-pr`](lua/plugins/pack-pr/) | `:PackPR` (`<leader>Pp`) — pick an open PR of one of your `github.com/<owner>/` plugins, install its branch headlessly, and restart into it; a reset entry per plugin goes back to the default branch. |
| [`pack-tweaks`](lua/plugins/pack-tweaks/) | `<CR>` on a line in the `vim.pack` update buffer opens that commit or tag in the browser. |
| [`projects`](lua/plugins/projects/) | `<leader>pp` — a [zoxide](https://github.com/ajeetdsouza/zoxide) picker that relaunches Neovim in the directory you choose, session and all. |
| [`scratch`](lua/plugins/scratch/) | `<leader>wt` — a per-project scratch file at `.tmp/scratch.md`, created on first use. |
| [`uv-scripts`](lua/plugins/uv-scripts/) | Filetype detection and a `ty` client pointed at the environment [uv](https://docs.astral.sh/uv/guides/scripts/) builds for a PEP 723 single-file script. |

## Working on it

```sh
mise run setup      # install the pinned tools, register the git hooks
mise run preflight  # lint (formatting, linters, type check) + test
mise run format     # stylua, rumdl, yamlfmt, taplo, pkl, shfmt, whitespace
mise run typecheck  # lua-language-server over the repo
mise run test       # the plenary suite
mise run coverage   # the suite under luacov, per-file coverage of lua/
mise run deps       # the specs' plugins, checked out at their locked revisions
mise run install    # update plugins via vim.pack
```

None of this is meant to be installed by anyone else — there's no bootstrap, no attempt at
portability, and a few things quietly assume my machine. Take whatever looks useful.
