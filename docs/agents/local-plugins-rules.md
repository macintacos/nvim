# Local plugin rules

These rules cover building or changing a plugin under `lua/plugins/<name>/`. `lua/plugins/gotoline/` shows the layout in full.

## Layout

- A local plugin is a directory holding `init.lua`, any helper modules, and a `README.md`.
- `init.lua` returns the module table, with a `setup()` when the plugin takes options or registers autocmds and keymaps.
- Helper modules require each other as `plugins.<name>.<module>`.

## Wiring

`plugin/local/<name>.lua` loads the plugin under a `-- Local plugin (no upstream repo)` header and a sentence on what it does, then calls `require("plugins.<name>").setup({ … })`. A local plugin that only extends a third-party plugin is wired from that plugin's own file instead, as `plugin/blink.lua` wires `blink-omni` and `blink-pairs`.

## Testability

- Expose a private function to specs by defining it on the module with a `_` prefix, as `lua/plugins/mini-pickers/files.lua` does with `M._postprocess`.
- For a non-trivial behavior, write the failing spec first, make it pass with the least code, then simplify while it stays green. `docs/agents/testing-rules.md` covers where specs go and how to run them.

## Documentation

- Once the behavior works, annotate every public API with LuaCATS:
  - `---@class <name>.Config` for a configuration table, with a `---@field` for each field.
  - A one-line `---` summary, `---@param`, and `---@return` on every public function.
  - `---@type` on module-level constants and caches.
- Adding, renaming, or removing a plugin updates both plugin indexes, the table in `README.md` and the list in `lua/plugins/README.md`. `docs/agents/documentation-rules.md` covers what else changes with it.
