# Development Guide

Rules for adding features to this Neovim configuration. See `CLAUDE.md` at the repo root for repository structure and plugin conventions.

## Adding a Plugin

1. Create `plugin/<name>.lua` with the required header and `vim.pack.add()`:

   ```lua
   -- github.com/author/plugin-name
   -- Short description of what the plugin does
   vim.pack.add({ "https://github.com/author/plugin-name" })
   require("plugin-name").setup({})
   ```

2. For lazy-loaded plugins, use `{ load = false }` and create stub keymaps or commands that call `vim.cmd.packadd()` on first use.
3. For version-pinned plugins, use `version = vim.version.range("1.x")` in the spec table.

## Modifying Core Configuration

Edit the appropriate file in `lua/config/`:

- **Options/globals**: `options.lua`
- **Keybindings**: `keymaps.lua` (use `require("helpers.mappings").Cmd()` for command mappings)
- **Autocommands**: `autocmds.lua` (every autocmd **must** have a comment explaining what/why/when)
- **Highlight groups**: `highlights.lua`

## Building Local Plugins

Local plugins live in `lua/plugins/<name>/` and follow the structure established by `gotoline`:

### Directory Structure

```text
lua/plugins/<name>/
├── init.lua       # Entry point, exports the module table and setup()
├── <helper>.lua   # Additional modules as needed
└── README.md      # Feature documentation
```

### Conventions

- **Entry point**: `init.lua` exports a module table. Include a `setup()` function if the plugin needs configuration.
- **Internal requires**: Use `require("plugins.<name>.<module>")` for helper modules.
- **Registration**: Wire up in the appropriate `plugin/*.lua` file:

  ```lua
  require("plugins.<name>").setup({ ... })
  ```

- **Test helpers**: Expose private functions for testing with a `_` prefix (e.g., `M._parse_query = parse_query`).

### Testing

Place tests in `tests/<name>/` using busted conventions:

```text
tests/<name>/
├── <module>_spec.lua   # One spec file per module
└── ...
```

Test files use `describe`/`it` blocks:

```lua
local mod = require("plugins.<name>.<module>")

describe("<module>", function()
  it("does something specific", function()
    local result = mod._helper("input")
    assert.equal("expected", result)
  end)
end)
```

Tests run via `mise run test` using `tests/minimal_init.lua` as the init file. Create temporary fixtures with `vim.fn.mkdir()` and `vim.fn.writefile()` and clean them up after each test.

## Development Process

### Test-Driven Development

For non-trivial features, use the TDD skill (red-green-simplify):

1. **Red**: Write a failing test that describes the desired behavior
2. **Green**: Write the minimum code to make the test pass
3. **Simplify**: Refactor while keeping tests green

Use `mise run test` to run the test suite. Use `mise run preflight` to run lint and test together (`mise run format` auto-fixes formatting separately).

### Documentation Pass (Final Step)

After implementation is complete, add LuaCATS annotations to all public APIs:

- **Module-level types**: `---@class <plugin_name>.Config` for configuration tables
- **Function signatures**: `---@param` and `---@return` on every public function
- **Field descriptions**: `---@field` on class/table fields
- **Variable types**: `---@type` on module-level constants and caches
- **Doc comments**: A one-line `---Description` above every annotated function

Example:

```lua
---Search files and headings in a directory.
---@param query string Text to search for
---@param root string Project root directory
---@param callback fun(results: MyPlugin.Result[])
---@return fun() cancel Cancellation function
function M.search(query, root, callback)
```

## Verification

After any changes, run `mise run preflight` to lint and test all files (`mise run format` auto-fixes formatting).
