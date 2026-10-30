# Local Plugins

This directory contains locally-defined Neovim plugins that live inside this configuration. Each subdirectory is a self-contained plugin module that can be loaded via `require("plugins.<name>")`.

## Plugins

- [`blink-omni`](blink-omni/) — a [blink.cmp](https://github.com/Saghen/blink.cmp) source that bridges the current buffer's `omnifunc` into the completion menu (used for Ghostty config files).
- [`blink-pairs`](blink-pairs/) — markdown emphasis pairing rules (`_`, `~`, `*`) and the symmetric-delimiter parity predicate for [blink.pairs](https://github.com/Saghen/blink.pairs), wired into its mapping schema by `plugin/blink.lua`; also takes over the engine's open/close stage for markdown's symmetric delimiters, whose Rust parser misreads in-span `_` as unterminated italics, and highlights each markdown delimiter left without a partner.
- [`branches`](branches/) — `<leader>gb` opens a centered picker over the repo's branches, local above remote, that switches to one, relaunches Neovim in the worktree that holds one, or creates one off HEAD.
- [`ftchooser`](ftchooser/) — `<leader>fl` sets the current buffer's filetype from a picker of human-friendly names, and remembers the choice per file across restarts.
- [`gotoline`](gotoline/) — exposes a `:GoToLine` command that opens a centered floating popup for jumping to a line in a project file.
- [`mini-pickers`](mini-pickers/) — customised [mini.pick](https://github.com/nvim-mini/mini.pick) registry entries: a tree-rendered LSP document-symbol outline, thinned workspace symbol pickers, and a per-line git blame picker.
- [`pack-pr`](pack-pr/) — `:PackPR` (`<leader>Pp`) picks an open PR of one of your installed `vim.pack` plugins (`github.com/<owner>/*`), installs its branch, and restarts Neovim into it for live smoke-testing.
- [`pack-tweaks`](pack-tweaks/) — tweaks to Neovim's built-in `vim.pack` plugin manager, each wired through `setup()`.
- [`pack-updates`](pack-updates/) — shows in the statusline how many installed `vim.pack` plugins have upstream commits you haven't pulled, checked in the background with `git ls-remote` and cached for 24 hours; `<leader>Pc` re-checks on demand.
- [`projects`](projects/) — `<leader>pp` picks a project from [zoxide](https://github.com/ajeetdsouza/zoxide) and relaunches Neovim there, so the shell ends up in the new directory too.
- [`scratch`](scratch/) — `<leader>wt` picks or names a per-project scratch file under `.tmp/scratch/` and opens it in a new tab; `<leader>wT` opens the pick in an 80% float.
- [`svelte-css`](svelte-css/) — an in-process LSP server that gives a Svelte project's own CSS classes hover, go-to-definition, and references, scoped the way Svelte scopes component styles.
- [`uv-scripts`](uv-scripts/) — filetype detection and a `ty` client pointed at the per-script environment [uv](https://docs.astral.sh/uv/guides/scripts/) builds for a PEP 723 single-file script.
- [`worktrunk`](worktrunk/) — [worktrunk](https://worktrunk.dev) commands under `<leader>gw`: the fish worktree picker in a float, quick switches, remove and merge, and opening or diffing the current file's copy in another worktree; anything that moves the shell to another worktree relaunches Neovim there, and a worktree removed from under Neovim moves it into the primary one.
