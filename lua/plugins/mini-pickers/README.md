# mini-pickers

Customised entries for [mini.pick](https://github.com/nvim-mini/mini.pick)'s registry, wired up by `require("plugins.mini-pickers").setup()` in `plugin/mini.lua`.

The registry entries this replaces are shipped by mini.pick and mini.extra; only the parts that needed different behaviour live here.

## Pickers

| `:Pick …`         | What changes                                                                 |
| ----------------- | ---------------------------------------------------------------------------- |
| `files`           | `<Space>` toggles the preview instead of the global `<C-p>`.                  |
| `lsp document_symbol` | Rendered as the file's outline — a real tree, not a flat list.            |
| `lsp workspace_symbol` | Rows stripped of their doubled `[Kind]` and path prefixes.              |
| `git_blame_line`  | New picker: commits that touched the line under the cursor.                   |

Other `lsp` scopes (`references`, `definition`, …) pass straight through to mini.extra — they are location lists with no symbol structure to recover.

## The outline

`vim.lsp.util.symbols_to_items` recurses into a `DocumentSymbol`'s `children` and appends them to one flat list, discarding the nesting. `MiniExtra.pickers.lsp` routes through it, so the outline requests `textDocument/documentSymbol` itself and walks the response in `symbols.lua`, where every item picks up the tree position it came from.

It renders in two modes.

**Idle** — document order, with tree connectors as inline virtual text:

```text
󰊕 make_symbol_show                                Function
└─󰊕 <anonymous>                                   Function
  ├─󰀫 rows                                        Variable
  └─󰀫 annotation                                  Variable
```

**Searching** — a query reorders rows by fuzzy score, which would leave the connectors describing a tree no longer on screen. They give way to a dim italic breadcrumb printed above each hit, so a deeply nested match costs no indentation:

```text
󰊕 kind_label_hl                                   Function
make_symbol_show › return
  󰀫 kind                                          Variable
  󰀫 kinds                                         Variable
```

The trail is a **virtual** line. mini.pick maps one item to one buffer line by position (`H.picker_set_lines`), so a real line would break selection; virtual ones also get the full window width, which is why the trail rarely needs trimming. Consecutive hits sharing a trail print it once.

One wrinkle comes with that: Neovim clips a `virt_lines_above` mark on the window's **topline**. The line counts toward the layout — `nvim_win_text_height` includes it — but there is no display row above the first line to draw it into, so the trail above the *first* result silently goes missing while every other one renders. `render.reserve_trail_row` fixes it by setting `topfill`, the mechanism that reserves that row. Two things it has to get right:

- **Deferred, on every render** — mini.pick sets the cursor after `source.show` returns, which resets the view.
- **Followed by a redraw** — `winrestview` moves the view without repainting, and mini.pick has already drawn the frame by then. Skip this and `topfill` reads as `1` while the screen still shows the un-reserved paint.

Screen-level behaviour like this is invisible to the headless test suite, which can only assert `topfill`. To check what actually renders, drive `outline._show` through `MiniPick.start` inside a real pty and read the grid back with `screenstring()`.

## Layout

| File            | Holds                                                                    |
| --------------- | ------------------------------------------------------------------------ |
| `init.lua`      | `setup()` — registry entries and the `lsp` scope dispatch.               |
| `symbols.lua`   | Flattening a document-symbol tree into items carrying `guides`/`crumb`.  |
| `outline.lua`   | The document-symbol picker and its two-mode renderer.                    |
| `workspace.lua` | Workspace symbol `show`/`match`.                                         |
| `kinds.lua`     | Which symbol kinds count as outline entries, per filetype.               |
| `render.lua`    | The extmark namespace and the lazily-built highlight groups.             |
| `git.lua`       | `git_blame_line`.                                                        |

Submodules are required on first use, so opening `:Pick files` never loads the LSP or git code.

## Notes

- **Kind filtering** (`kinds.lua`) exists because servers emit a symbol per table key — without it a Lua outline is mostly `[1]`, `[2]`, and `desc`. Data filetypes (`toml`, `json`, `yaml`, `markdown`) are exempt, since there `Object`/`Array`/`String` *are* the structure. lua_ls additionally reports every `if`/`for`/`else`/`elseif` block as a `Package` symbol, which is excluded for `lua` only — other languages use `Package` for real packages.
- **Italics** on the breadcrumb come from `MiniPickSymbolCrumb`. Terminals whose font ships Oblique rather than Italic faces render it upright; that is a font-matching issue, not a highlight one.
- Servers answering with flat `SymbolInformation[]` instead of `DocumentSymbol[]` have no `children`; the outline degrades to a flat list and takes its breadcrumb from `containerName`.

## Tests

```sh
mise run test
```

Specs live in `tests/mini-pickers/`, covering the tree walk, breadcrumb fitting, and per-filetype kind selection.
