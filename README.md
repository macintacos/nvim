# nvim

![A recording of the config navigating its own repo: the which-key leader menu, a fuzzy file picker opening plugin/which-key.lua, go-to-definition into a helper module, mini.files walking lua/plugins, an LSP symbol picker, a live grep, the changeset sidebar previewing this branch's changes, and a search over every keybinding.](./assets/preview.gif)

This is where the work happens now. It used to run on lazy.nvim, and this README used to
open by apologising for itself and sending you to VSCode for anything serious. Neither is
true any more.

It's [a repo of its own](https://github.com/macintacos/nvim), pulled into
[my dotfiles](https://github.com/macintacos/dotfiles) as a chezmoi external so it travels
under its own history. [Ghostty](https://ghostty.org/) is the terminal;
[herdr](https://herdr.dev), the agent multiplexer it all runs inside.

## What's in the recording

The config navigating its own repo, on a branch eight commits ahead of trunk:

- `<leader>ff` finds `plugin/which-key.lua` in
  [mini.pick](https://github.com/nvim-mini/mini.pick), and `gd` follows its `Cmd` helper
  into `lua/helpers/mappings.lua`.
- `<leader>fu` reveals that file in [mini.files](https://github.com/nvim-mini/mini.files)
  and walks over to the gotoline plugin, where `<leader>ji` jumps to an LSP symbol.
- `<leader>sp` greps for the changeset mapping, and `<leader>gp` opens
  [changeset.nvim](https://github.com/macintacos/changeset.nvim)'s sidebar: `]h` previews
  each changed row before `<CR>` opens one.
- `<leader>bb` switches back to an open buffer, and `<leader><leader>` searches every
  keybinding.

[VHS](https://github.com/charmbracelet/vhs) records it from `assets/preview.tape`; run
`vhs assets/preview.tape` from the repo root to record it again.

## The shape of it

**No plugin manager.** [`vim.pack`](https://neovim.io/doc/user/pack.html) ships with
Neovim 0.12 and is enough. Each plugin gets a file under `plugin/` — or a family gets a
directory, which is why `plugin/mini/` holds the whole mini set — and Neovim sources them
itself after `init.lua`. Versions land in `nvim-pack-lock.json`. Loading is one of three tiers:
eager, deferred behind a `vim.schedule`, or lazy behind a stub command or keymap that
`packadd`s the real thing on first use.

**[mini.nvim](https://github.com/nvim-mini/mini.nvim) is the spine.** The picker, the file
explorer, sessions, the statusline, the statuscolumn, notifications and `vim.ui.input` are
all mini — sixteen modules, one file each under `plugin/mini/`, fourteen on `stable` and
two tracking `main` until they tag. [snacks.nvim](https://github.com/folke/snacks.nvim)
covers what mini doesn't: indent guides, scope, smooth scroll, the terminal, lazygit, zen
mode, image rendering, and the big-file and quickfile guards. Its notifier,
input and `vim.ui.select` are switched off, each with a comment at both ends naming the
mini module that took the job.

**The colours follow the terminal.** Dracula Pro's Van Helsing (dark) and Alucard (light),
in the colours of the shared palette the dotfiles deploy to `~/.config/palette/palette.json`.
Dracula Pro is a paid theme, so this repo doesn't ship it: the dotfiles deploy its vim scheme
privately as a start package. `colors/dracula-pro.lua` picks the variant from
`'background'`, which Neovim keeps in step with the terminal, so an appearance flip re-themes
a running editor. Without the palette file Pro's own variant loads; without Dracula Pro,
Neovim's default scheme does, under this config's own groups in the palette's colours when
the palette file exists.

**Local plugins are first-class.** Eleven of them under `lua/plugins/`, each with specs
in `tests/`. They exist because nothing upstream did the thing: a project
switcher that relaunches Neovim through the fish `nvim` wrapper so the shell ends up in
the new directory too, an update checker that runs `git ls-remote` in libuv's thread pool
and feeds a spinner into the statusline, a picker that points a plugin's spec at an open
PR's branch so it can be smoke-tested live.

**It's maintained like a project.** A [plenary](https://github.com/nvim-lua/plenary.nvim)
spec suite with a startup smoke test and luacov coverage, selene and stylua over the Lua,
emmylua_check type-checking it, and [hk](https://hk.jdx.dev/) on the hooks: format
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
| [`pack-updates`](lua/plugins/pack-updates/) | A statusline count of plugins with upstream commits you haven't pulled, checked in the background with `git ls-remote` and cached for a day; `<leader>Pc` re-checks. |
| [`projects`](lua/plugins/projects/) | `<leader>pp` — a [zoxide](https://github.com/ajeetdsouza/zoxide) picker that relaunches Neovim in the directory you choose, session and all. |
| [`scratch`](lua/plugins/scratch/) | `<leader>wt` — a per-project scratch file at `.tmp/scratch.md`, created on first use. |
| [`uv-scripts`](lua/plugins/uv-scripts/) | Filetype detection and a `ty` client pointed at the environment [uv](https://docs.astral.sh/uv/guides/scripts/) builds for a PEP 723 single-file script. |

## Working on it

```sh
mise run setup      # install the pinned tools, register the git hooks
mise run preflight  # lint (formatting, linters, type check) + test
mise run format     # stylua, rumdl, yamlfmt, taplo, pkl, shfmt, whitespace
mise run lint       # formatting check, linters, type check; changes nothing
mise run typecheck  # emmylua_check over the repo
mise run test       # the plenary suite
mise run coverage   # the suite under luacov, per-file coverage of lua/
mise run deps       # the plugins the specs and type check read, at their locked revisions
mise run install    # update plugins via vim.pack
```

None of this is meant to be installed by anyone else — there's no bootstrap, no attempt at
portability, and a few things quietly assume my machine. Take whatever looks useful.
