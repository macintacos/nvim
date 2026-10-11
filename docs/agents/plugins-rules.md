# Plugin rules

These rules cover `plugin/`, the `PackChanged` handler in `init.lua`, and `nvim-pack-lock.json`.

## Files and headers

- Each plugin gets its own `plugin/<short-name>.lua`, and a family configured together shares a directory, as `plugin/mini/` and `plugin/lsp/` do.
- Every file opens with a comment header: the repo link without its scheme, such as `-- github.com/folke/flash.nvim`, then one sentence on what the plugin does, wrapped over more lines if it needs them. The mini files add a `-- Docs:` line linking the module's help file. A file that wires a local plugin opens with `-- Local plugin (no upstream repo)` instead of a link. A file that loads something other than a `vim.pack` plugin says so on its first line, as `plugin/ghostty.lua` does.

## Specs and versions

- Pass `vim.pack.add()` a URL, or a table whose `version` pins a branch, tag, or semver range: `{ src = "…", version = "stable" }` for the mini modules, `version = vim.version.range("1.x")` for blink.cmp. List plugins configured together in one call.
- `vim.pack` writes `nvim-pack-lock.json`, so change a version in the spec, never in the lockfile. `mise run install` runs `vim.pack.update()` headless.

## Load tiers

Load each plugin as late as it allows, because every eager plugin adds to startup time.

- **Eager:** `vim.pack.add()` with the default `load`, for a plugin that has to act before the first screen draws. Example: `plugin/gitsigns.lua`.
- **Deferred:** `vim.pack.add({ … }, { load = false })`, then `vim.cmd.packadd()` and `setup()` inside `vim.schedule()`, for a plugin needed soon after startup but not for the first screen. Example: `plugin/nvim-surround.lua`.
- **Lazy:** `{ load = false }` plus a trigger that calls `vim.cmd.packadd()` on first use. The trigger is one of:
  - a `once` autocmd, as `plugin/conform.lua` loads on the first `BufWritePre`;
  - a `FileType` autocmd, as in `plugin/lsp/rust.lua`;
  - a stub user command that deletes itself, loads the plugin, and re-runs the call, as in `plugin/grug-far.lua`.

## Build steps

A plugin that compiles native code after cloning gets a case in `init.lua`'s `PackChanged` handler. `vim.pack` fires that event once per plugin on each install and update. The handler runs `cargo build --release` for blink.cmp and `:TSUpdate` for nvim-treesitter.

## Registering a required plugin

- A plugin that Lua in this repo `require`s goes in `.emmyrc.json`'s `workspace.library` and in the `plugins` list in `tests/support/deps.lua`. Without both, the type check reports `unresolved-require` and specs cannot load it. Run `mise run deps` afterwards to check it out.
- A plugin that publishes a global, such as a mini module's `MiniPick`, also goes in `vim.yml`, or selene reports it as undefined. A mini global also goes in `types/mini.lua`, because emmylua cannot see mini's own global assignment.
