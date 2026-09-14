# mini-pickers

Customised entries for [mini.pick](https://github.com/nvim-mini/mini.pick)'s registry, wired up by `require("plugins.mini-pickers").setup()` in `plugin/mini.lua`.

The registry entries this replaces are shipped by mini.pick and mini.extra; only the parts that needed different behaviour live here.

## Pickers

| `:Pick …`         | What changes                                                                 |
| ----------------- | ---------------------------------------------------------------------------- |
| `files`           | Always `rg`, hidden files included, plus a list of ignored paths. `<Space>` toggles the preview instead of the global `<C-p>`. |
| `grep_live`       | Hits grouped under a virtual file header, with the line number right-aligned. |
| `lsp document_symbol` | Rendered as the file's outline — a real tree, not a flat list.            |
| `lsp workspace_symbol` | Rows stripped of their doubled `[Kind]` and path prefixes.              |
| `git_blame_line`  | New picker: commits that touched the line under the cursor.                   |

The other `lsp` scopes (`references`, `definition`, …) are location lists with no symbol structure to recover. `locations.lua` only thins their rows to the path, with the `line:col` right-aligned — the side preview shows the line itself, so the query matches paths alone. `gr` opens the `references` one.

## The side preview

mini.pick draws its preview *in place of* the list. `preview.lua` hangs a second float right of the list instead, showing the current item as it moves:

```text
┌─ list (40%) ──────────┐┌─ preview (the rest) ───────────────────────┐
│ 󰢱 lua/init.lua        ││ local M = {}                               │
│   return M         12 ││ …the file, the hit's line highlighted      │
└───────────────────────┘└────────────────────────────────────────────┘
```

A picker opts in with `window = preview.window()` — `files`, `grep_live`, and every `lsp` scope do; `vim.ui.select` and the rest keep the single window. Below `MIN_COLUMNS` (120) no float opens and the list takes the whole width, as before; the in-place toggle still works there.

The float is filled by the picker's own `source.preview`, which is what makes location items land on their line: `MiniPick.default_preview` positions the cursor in whichever window shows the buffer it is handed, not the picker's. The landing line then sits 30% down, like the LSP jumps.

mini.pick fires no event when the current item moves, so the float re-renders after every key the picker reads (`vim.on_key`), on `MiniPickMatch` for async items and query changes, and re-fits itself on `VimResized`.

## The files picker

`MiniPick.builtin.files` picks a tool at runtime — `rg`, then `fd`, then `git`, then a Lua walk — and hardcodes the arguments it calls it with. `files.lua` spells the `rg` call out instead, so the flags are ours:

```sh
rg --files --color=never --hidden --glob '!.git' . CLAUDE.md
```

`--hidden` is what puts `.mise/tasks/`, `.luarc.json`, and `.github/` in the results at all; rg walks past dotfiles without it, and `!.git` is then the one directory it must be kept out of.

Files an ignore file hides are a separate problem, and **`M.extra` in `files.lua` is the list of them** — `CLAUDE.md` and `.env` to start with. They are appended as literal path arguments, which is the only spelling that beats `.gitignore` while leaving the rest of the listing alone:

| Approach                    | Result                                                     |
| --------------------------- | ---------------------------------------------------------- |
| `-g 'CLAUDE.md'`            | Outranks `.gitignore`, but one positive glob turns the run into a whitelist — nothing else is listed. |
| `--ignore-file` with `!CLAUDE.md` | Loses to `.gitignore`; exclusions in that file still apply, un-ignores do not. |
| `. CLAUDE.md` as path args  | Everything under `.`, plus the ignored path. What this uses. |

Two consequences, both handled in `_postprocess`/`_command`: rg prefixes the paths it walks from `.` with `./` but returns the extras bare, so a file reachable both ways arrives twice under two spellings; and it errors on a path that does not exist, so extras missing from the project are dropped before the call rather than listed for every repo that has no `CLAUDE.md`.

Nothing expands the entries — the spawn has no shell — so each is a plain relative path to a file or a directory, never a glob.

## The live grep

`MiniPick.default_show` draws an rg hit as `path│lnum│col│text`, which repeats the path on every row of a file and starts the matched text three columns in:

```text
 lua/plugins/mini-pickers/render.lua│44│9│  local comment = vim.api.nvim…
 lua/plugins/mini-pickers/render.lua│61│11│    local comment = vim.api.n…
 lua/plugins/mini-pickers/outline.lua│33│3│  MiniPick.default_show(buf_i…
```

`grep.lua` keeps the items — they are the raw rg strings mini.pick parses for choosing and previewing — and changes only the drawing:

```text
󰢱 lua/plugins/mini-pickers/render.lua
  local comment = vim.api.nvim_get_hl(0, { name = "Comment" })      44
  local comment = vim.api.nvim_get_hl(0, { name = "Comment" })      61
󰢱 lua/plugins/mini-pickers/outline.lua
  MiniPick.default_show(buf_id, display, query)                     33
```

The header is the same `virt_lines_above` mark the outline's breadcrumb uses, with the same `render.reserve_trail_row` fix for the first row, and leading indentation is stripped from the text so a deeply nested match does not start off the right edge.

The preview marks the whole match. rg reports only where a hit starts, so `grep.lua` re-runs the query as a Vim very-magic regex from that column to find where it ends; characters only Vim treats as operators (`<>=@%&~`) are escaped first. A pattern Vim cannot compile or match there — inline flags, lookarounds — keeps mini.pick's one-character mark.

One header covers a whole file because `grep_live` sets its items with `do_match = false` and rg walks a file at a time — hits arrive already grouped, so a run of equal paths is a run of hits in one file. Nothing re-sorts them; a query change re-runs rg rather than reordering what is on screen.

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

One wrinkle comes with that: Neovim clips a `virt_lines_above` mark on the window's **topline**. The line counts toward the layout — `nvim_win_text_height` includes it — but there is no display row above the first line to draw it into, so the trail above the *first* result silently goes missing while every other one renders. `render.reserve_trail_row` fixes it by setting `topfill`, the mechanism that reserves that row. It has to run **synchronously, on every render, after `MiniPick.default_show`**: rewriting the buffer's lines (`nvim_buf_set_lines`) drops `topfill` back to `0`, and mini.pick draws the frame as soon as `source.show` returns. Deferring it lets that frame paint the whole list a row higher, then jump back — a stutter on every move.

Screen-level behaviour like this is invisible to the headless test suite, which can only assert `topfill`. To check what actually renders, drive `outline._show` through `MiniPick.start` inside a real pty and read the grid back with `screenstring()`.

## Layout

| File            | Holds                                                                    |
| --------------- | ------------------------------------------------------------------------ |
| `init.lua`      | `setup()` — registry entries and the `lsp` scope dispatch.               |
| `files.lua`     | The `rg` invocation and `M.extra`, the ignored paths added back to it.   |
| `grep.lua`      | The live grep's item parsing and its file-header renderer.               |
| `symbols.lua`   | Flattening a document-symbol tree into items carrying `guides`/`crumb`.  |
| `outline.lua`   | The document-symbol picker and its two-mode renderer.                    |
| `workspace.lua` | Workspace symbol `show`/`match`.                                         |
| `locations.lua` | `show`/`match` for references, definitions, and the other location lists. |
| `kinds.lua`     | Which symbol kinds count as outline entries, per filetype.               |
| `render.lua`    | The extmark namespace and the lazily-built highlight groups.             |
| `preview.lua`   | The side preview float and the list/preview width split.                 |
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
