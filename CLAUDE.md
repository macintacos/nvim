# AGENTS.md

This document provides guidance for AI agents working with this Neovim configuration repository.

## Documentation Reference

When working with this configuration, consult the official Neovim documentation:

- **Neovim Help**: `:help` within Neovim or https://neovim.io/doc/
- **Neovim Lua Guide**: `:help lua-guide` or https://neovim.io/doc/user/lua-guide.html
- **Neovim API**: `:help api` or https://neovim.io/doc/user/api.html
- **lazy.nvim Documentation**: https://lazy.folke.io/

## Repository Structure

```
.
├── init.lua              # Entry point - loads lua/config/lazy.lua
├── lua/
│   ├── config/           # Core configuration modules
│   │   ├── lazy.lua      # lazy.nvim bootstrap and setup
│   │   ├── options.lua   # Neovim options and globals
│   │   ├── keymaps.lua   # Global keybindings
│   │   ├── autocmds.lua  # Autocommands
│   │   ├── highlights.lua# Custom highlight groups
│   │   └── helpers.lua   # Utility functions
│   └── plugins/          # Plugin specifications (one file per plugin)
├── justfile              # Task runner recipes (format, lint, check)
├── lazy-lock.json        # Plugin version lockfile (managed by lazy.nvim)
└── stylua.toml           # Lua formatter configuration
```

## Plugin Manager: lazy.nvim

This configuration uses [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management.

### Plugin Specification Pattern

Each plugin is defined in its own file under `lua/plugins/`. Files should return a `LazySpec` table:

```lua
---@module "lazy"
---@type LazySpec
return {
  "author/plugin-name",
  -- Plugin options here
  opts = {},
}
```

### Common Plugin Spec Fields

- `opts` - Configuration passed to `plugin.setup(opts)`
- `config` - Function called when plugin loads (use `opts` when possible)
- `init` - Function called at startup before plugin loads
- `lazy` - Whether to lazy-load (default: true)
- `event` - Events that trigger loading (e.g., `"BufReadPre"`, `"VeryLazy"`)
- `ft` - Filetypes that trigger loading
- `cmd` - Commands that trigger loading
- `keys` - Keymaps that trigger loading
- `dependencies` - Plugins that must load first
- `build` - Build command run after install/update
- `priority` - Load order for non-lazy plugins (higher = earlier)

### Type Annotations

Use LuaCATS annotations for better IDE support:

```lua
---@module "lazy"
---@type LazySpec
return {
  "plugin/name",
  ---@module "plugin-name"
  ---@type PluginConfig
  opts = {},
}
```

## Configuration Loading Order

1. `init.lua` → requires `config.lazy`
2. `config/lazy.lua`:
   - Bootstraps lazy.nvim
   - Loads `config/options.lua`
   - Loads `config/autocmds.lua`
   - Loads `config/keymaps.lua`
   - Loads `config/highlights.lua`
   - Initializes lazy.nvim with `{ import = "plugins" }`
3. lazy.nvim loads all files from `lua/plugins/`

## Conventions

### File Naming

- Plugin files: `lua/plugins/<plugin-name>.lua` (use the plugin's short name)
- Files prefixed with `_` (e.g., `_LSP.lua`) indicate broader configurations

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
- **neo-tree.nvim** - File explorer
- **which-key.nvim** - Keymap hints

## Making Changes

1. **Adding a plugin**: Create `lua/plugins/<plugin-name>.lua` returning a LazySpec
2. **Modifying options**: Edit `lua/config/options.lua`
3. **Adding keymaps**: Edit `lua/config/keymaps.lua` or add to plugin's `keys` spec
4. **Adding autocommands**: Edit `lua/config/autocmds.lua`

## Testing Changes

After making changes:

1. Restart Neovim or run `:Lazy reload <plugin>`
2. Check for errors with `:messages` or `:checkhealth`
3. Run `:Lazy` to manage plugins

## Code Style

- Format Lua files with StyLua (config in `stylua.toml`)
- Use type annotations where helpful
- Comment non-obvious configurations

## Lua Development Tooling

This configuration includes integrated Lua development tools:

### Type Annotations

- Use LuaCATS annotations (`---@param`, `---@return`, `---@type`, `---@class`) for type safety
- Plugin specs must include `---@module "lazy"` and `---@type LazySpec`
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

