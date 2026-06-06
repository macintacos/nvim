This document provides guidance for AI agents working with this Neovim configuration repository.

<!-- CODEGRAPH_START -->
## CodeGraph

**First check.** If `.codegraph/` doesn't exist in this repo, ask once: *"This project doesn't have CodeGraph initialized — want me to run `codegraph init -i`?"* If they decline or skip, ignore the rest of this section.

**The habit to override.** When `.codegraph/` exists, `codegraph_*` is the default for any question about symbols, call graphs, or "how does X work" — not grep + Read. Codegraph IS the pre-built index: a full AST parse already sitting in SQLite, sub-millisecond reads. If you're about to grep for a function name or Read a file to find a definition, stop — `codegraph_search` / `codegraph_context` is one call and returns more (kind, location, signature, docstring).

Grep and Read are for **literal text** — log messages, comments, string contents — or files you already have open.

The detailed tool-selection table and common chains live in the codegraph MCP server's own instructions, which are already loaded into every session. This section adds the project-level emphasis those instructions can't carry: *when* to reach for codegraph in the first place.

### Worked example

User: *"How does auth work in this repo?"*

- **Wrong reflex**: `grep -ri "auth" .`, Read four files, maybe spawn an Explore subagent to make sense of it.
- **Right reflex**: `codegraph_context("authentication")` → if more breadth is needed, one `codegraph_explore` over the symbols it surfaced. Two calls, done. Spawning a subagent here repeats work the index already did.

### Red flags — you're about to skip codegraph

| Thought | Reality |
|---|---|
| "I'll just grep quickly to find it" | `codegraph_search` is faster and returns kind + location + signature in one call. |
| "Let me Read the file first to orient" | If you're looking up a symbol, `codegraph_node` returns just that symbol's source. |
| "I'll spawn an Explore subagent" | Codegraph IS the pre-built index — the agent would re-derive what's already indexed. |
| "Let me verify the codegraph result with grep" | Don't. AST parse beats text search; re-verifying wastes context. |
| "I'll chain `codegraph_search` then `codegraph_node`" | Use `codegraph_context` — one call instead of two. |

### Index lag

The file watcher debounces ~500ms behind writes. Don't re-query codegraph immediately after editing a file in the same turn — give it a beat, or trust your edit.
<!-- CODEGRAPH_END -->

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
├── mise.toml             # Tool versions and task runner recipes (format, lint, check)
├── mise.lock             # Pinned tool versions (managed by mise)
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

After editing Lua files, run `mise run check` to lint, format, and test all files. Individual tasks:

- `mise run format` — auto-fix formatting with stylua
- `mise run lint` — run selene linter
- `mise run check` — run lint, format, and tests
- `mise run test` — run plenary tests
- `mise run install` — install Neovim plugins

Tool versions are managed by mise (`mise install` to install, `mise.lock` pins exact versions).

### Verification After Changes

1. Run `mise run check` to lint, format, and test all Lua files
2. Save a Lua file — confirm stylua auto-formats
3. Check for linting warnings in the diagnostics
4. Run `:ConformInfo` to verify formatter config
5. Run `:LspInfo` to verify lua_ls is attached
