# AGENTS.md

This document provides guidance for AI agents working with this Neovim configuration repository.

## Documentation Reference

When working with this configuration, consult the official Neovim documentation:

- **Neovim Help**: `:help` within Neovim or https://neovim.io/doc/
- **Neovim Lua Guide**: `:help lua-guide` or https://neovim.io/doc/user/lua-guide.html
- **Neovim API**: `:help api` or https://neovim.io/doc/user/api.html
- **vim.pack**: Built-in plugin manager (Neovim 0.12.0+) — `:help vim.pack`

## Repository Structure

```
.
├── init.lua              # Entry point: vim.loader, core config, PackChanged builds
├── plugin/               # Plugin files (auto-sourced by Neovim after init.lua)
│   ├── snacks.lua        # Each file calls vim.pack.add() + setup() directly
│   ├── treesitter.lua
│   ├── lsp.lua
│   └── ...
├── lua/
│   └── config/           # Core configuration modules
│       ├── options.lua   # Neovim options and globals
│       ├── keymaps.lua   # Global keybindings
│       ├── autocmds.lua  # Autocommands
│       ├── highlights.lua# Custom highlight groups
│       └── helpers.lua   # Utility functions
├── justfile              # Task runner recipes (format, lint, check)
├── nvim-pack-lock.json   # Plugin version lockfile (managed by vim.pack)
└── stylua.toml           # Lua formatter configuration
```

## Plugin Manager: vim.pack (built-in)

This configuration uses Neovim's built-in `vim.pack` for plugin management. No external plugin manager is needed.

### Plugin File Pattern

Each plugin lives in its own file under `plugin/`. Files are auto-sourced by Neovim at startup (alphabetically, after init.lua). Every file starts with a header comment and calls `vim.pack.add()` directly:

```lua
-- github.com/author/plugin-name
-- Short description of what the plugin does
vim.pack.add({ "https://github.com/author/plugin-name" })
require("plugin-name").setup({
  -- Plugin options here
})
```

### Plugin Spec Format

- **String**: `"https://github.com/author/plugin"` — simple URL
- **Table**: `{ src = "https://github.com/author/plugin", version = "stable" }` — with options
- **List**: Multiple specs in one `vim.pack.add()` call for related plugins

### Loading Strategies

Plugins are loaded in three tiers:

1. **Eager** — `vim.pack.add()` with default `load` (installs and loads immediately)
2. **Deferred** — `vim.pack.add({ ... }, { load = false })` + `vim.schedule()` to packadd after startup
3. **Lazy** — `vim.pack.add({ ... }, { load = false })` + a trigger (`once` autocmd, stub command, or stub keymap) that calls `vim.cmd.packadd()` on first use

## Configuration Loading Order

1. `init.lua`:
   - Enables `vim.loader` for fast bytecode caching
   - Loads `config/options.lua`, `config/autocmds.lua`, `config/keymaps.lua`, `config/highlights.lua`
   - Registers `PackChanged` autocommand for plugin build steps
2. Neovim auto-sources all `plugin/*.lua` files (alphabetically)
   - Each file calls `vim.pack.add()` and configures its plugin(s)

## Conventions

### File Naming

- Plugin files: `plugin/<plugin-name>.lua` (one per plugin, use the plugin's short name)

### File Header

Every `plugin/*.lua` file **must** start with:
```lua
-- <repo link>
-- <short, simple sentence describing the plugin>
```

### Autocommands

- Every `nvim_create_autocmd` **must** have a comment above it explaining what it does, why it exists, and when it fires
- For lazy-loading autocmds, explain which plugin is being loaded and what triggers it

### Keymaps

- Leader key: `<Space>`
- Local leader: `\`
- Use `vim.keymap.set()` for keybindings
- Include `desc` for which-key integration
- Helper: `require("config.helpers").Cmd()` wraps commands with `<Cmd>...<CR>`

### Globals

Important globals defined in `config/options.lua`:

- `vim.g.mapleader = " "`
- `vim.g.maplocalleader = "\\"`
- `vim.g.snacks_animate` - Controls Snacks.nvim animations

## Key Plugins

- **snacks.nvim** - UI utilities (picker, notifier, terminal, etc.)
- **mason.nvim + mason-lspconfig.nvim** - LSP server management
- **nvim-treesitter** - Syntax highlighting and code understanding
- **blink.cmp** - Completion engine
- **mini.files** - File explorer
- **which-key.nvim** - Keymap hints

## Making Changes

1. **Adding a plugin**: Create `plugin/<plugin-name>.lua` with `vim.pack.add()` + setup
2. **Modifying options**: Edit `lua/config/options.lua`
3. **Adding keymaps**: Edit `lua/config/keymaps.lua` or add to the plugin's `plugin/*.lua` file
4. **Adding autocommands**: Edit `lua/config/autocmds.lua`

## Testing Changes

After making changes:

1. Restart Neovim
2. Check for errors with `:messages` or `:checkhealth vim.pack`
3. Run `:lua vim.pack.update()` to manage plugins

## Code Style

- Format Lua files with StyLua (config in `stylua.toml`)
- Use type annotations where helpful
- Comment non-obvious configurations

## Lua Development Tooling

This configuration includes integrated Lua development tools:

### Type Annotations

- Use LuaCATS annotations (`---@param`, `---@return`, `---@type`, `---@class`) for type safety
- lazydev.nvim provides Neovim API completions and type definitions

### Formatting and Linting

- **stylua** formats Lua on save via conform.nvim (also formats sh with shfmt, yaml with yamlfmt)
- **selene** lints Lua on save/open via nvim-lint (also lints sh with shellcheck, markdown with markdownlint-cli2)
- `<leader>f=` triggers manual format via conform (falls back to LSP)

### Adding Globals to Selene

To suppress selene warnings for new runtime globals, add them to `vim.yml`:

```yaml
globals:
  NewGlobal:
    any: true
```

### CLI Tools

After editing Lua files, run `just check` to lint and format all files. Individual recipes:

- `just format` — auto-fix formatting with stylua
- `just lint` — run selene linter
- `just check` — run both lint and format

### Verification After Changes

1. Run `just check` to lint and format all Lua files
2. Save a Lua file — confirm stylua auto-formats
3. Check for linting warnings in the diagnostics
4. Run `:ConformInfo` to verify formatter config
5. Run `:LspInfo` to verify lua_ls is attached
