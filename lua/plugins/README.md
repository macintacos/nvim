# Local Plugins

This directory contains locally-defined Neovim plugins that live inside this configuration. Each subdirectory is a self-contained plugin module that can be loaded via `require("plugins.<name>")`.

## Plugins

- [`blink-markdown-refs`](blink-markdown-refs/) — a [blink.cmp](https://github.com/Saghen/blink.cmp) source for referencing files, headings, and content across projects in markdown files.
- [`blink-omni`](blink-omni/) — a [blink.cmp](https://github.com/Saghen/blink.cmp) source that bridges the current buffer's `omnifunc` into the completion menu (used for Ghostty config files).
- [`gotoline`](gotoline/) — exposes a `:GoToLine` command that opens a centered floating popup for jumping to a line in a project file.
- [`pack-tweaks`](pack-tweaks/) — tweaks to Neovim's built-in `vim.pack` plugin manager, each wired through `setup()`.
