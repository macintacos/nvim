# Local Plugins

This directory contains locally-defined Neovim plugins that live inside this configuration. Each subdirectory is a self-contained plugin module that can be loaded via `require("plugins.<name>")`.

## Plugins

- [`blink-omni`](blink-omni/) — a [blink.cmp](https://github.com/Saghen/blink.cmp) source that bridges the current buffer's `omnifunc` into the completion menu (used for Ghostty config files).
- [`ftchooser`](ftchooser/) — `<leader>fl` sets the current buffer's filetype from a picker of human-friendly names, and remembers the choice per file across restarts.
- [`gotoline`](gotoline/) — exposes a `:GoToLine` command that opens a centered floating popup for jumping to a line in a project file.
- [`mini-pickers`](mini-pickers/) — customised [mini.pick](https://github.com/nvim-mini/mini.pick) registry entries: a tree-rendered LSP document-symbol outline, thinned workspace symbol pickers, and a per-line git blame picker.
- [`pack-pr`](pack-pr/) — `:PackPR` picks an open PR across managed GitHub repos and points the matching `vim.pack` spec at the PR's branch for live smoke-testing.
- [`pack-tweaks`](pack-tweaks/) — tweaks to Neovim's built-in `vim.pack` plugin manager, each wired through `setup()`.
- [`projects`](projects/) — `<leader>pp` picks a project from [zoxide](https://github.com/ajeetdsouza/zoxide) and relaunches Neovim there, so the shell ends up in the new directory too.
- [`scratch`](scratch/) — `<leader>wt` opens a per-project scratch file at `.tmp/scratch.md`; `<leader>wT` opens the same file in an 80% float.
- [`uv-scripts`](uv-scripts/) — filetype detection and a `ty` client pointed at the per-script environment [uv](https://docs.astral.sh/uv/guides/scripts/) builds for a PEP 723 single-file script.
