# svelte-css

Hover, go-to-definition, and references for a Svelte project's own CSS classes.

The Svelte language server's CSS support works only inside `<style>` and has no
definition or references for classes, and the Tailwind server knows only Tailwind
utilities. `css-class-lsp` fills the gap but treats every component's `<style>` block as
global, while Svelte scopes each one to its own component. This plugin fills it with
Svelte's scoping.

## What it does

It runs an in-process LSP server named `svelte_css` for the `svelte` and `css` filetypes,
rooted at the nearest `svelte.config.js`, `svelte.config.mjs`, or `svelte.config.ts`. A
buffer with none of these above it gets no server, so stylesheets in other projects are
left alone. Since it is an ordinary LSP client, the existing hover (`gh`), `gd`, and
`grr` pick it up with no keymaps of its own.

With the cursor on a class, either a token in a `class="…"` attribute, a
`class:name={…}` directive, or a `.name` selector:

- **Hover** shows every rule that styles an element carrying the class, each under its
  root-relative path and line.
- **Definition** jumps to those rules.
- **References** lists every use of the class in markup, plus every rule that names it
  when the request asks for declarations.

The server answers `null` for a class no rule names, such as a Tailwind utility, so it
stays quiet beside the Svelte and Tailwind servers.

## Scoping

"Stylesheets" are the `*.css` files under the root that `rg --files` lists. It honors
`.gitignore` even outside a git repository, and always skips `node_modules`.

The rules that reach a class are those in its own file, in every stylesheet, and in
every `:global(.x)` selector. Another component's scoped rule never counts.

Hover and definition show only the rules that style the element carrying the class:
those with the class in the rightmost compound of one of their selectors. `.a.b`,
`.a:hover`, and `.x > :global(.a)` style `a`. `.a .b`, `.a > .b`, `.a + .b`, and
`.a ~ .b` style only `b`. Inside that compound, `:global(…)`, `:is(…)`, and `:where(…)`
count, while `:not(…)` and `:has(…)` do not. A nested rule is judged by its own selector.

References find every use of the class, whether its rules style the element or only
qualify another, as `.wrapper` does in `.wrapper :global(.child)`. They give the same
uses from a selector as from markup, wherever the rules that name the class reach:

| From | Uses (references) |
| --- | --- |
| A selector in a stylesheet, or a `:global(.x)` selector | Every component's markup |
| A selector in a component's `<style>` | The component's own markup |
| A class in a component's markup | Every component's markup when a stylesheet or `:global` rule names the class, else the component's own |

A `class` on a component's tag, as in `<Button class="x">` or `<ui.Button class="x">`,
passes a prop rather than styling an element, so Svelte doesn't apply the file's scoped
rules to it. Those rules skip it, while stylesheet and `:global` rules still reach it.

## Design

- **Pure core, thin shell.** `parse.lua` turns source text into class definitions and
  uses. `resolve.lua` applies the scoping above to a table of parsed files. `server.lua`
  does the I/O: it lists the project's files, reads each from its loaded buffer when
  open (so unsaved edits count), otherwise from disk, and answers the LSP requests.
- **Tree-sitter.** The `svelte` parser injects only `css` into `<style>`. Its stock
  JavaScript injections would cost four times as much and hold no classes.
- **Cache.** Each file's parse is kept until its buffer's changedtick or its file's
  mtime changes. On the caret project (about 240 files), the first request takes about
  100 ms and later ones about 10 ms, most of which is `rg`.

## Not covered

Classes built inside `class={…}` expressions (`cn(…)`, arrays, objects), and class
tokens that touch an interpolation such as `btn-{size}`. SCSS and Less, whose
`<style lang="…">` blocks are read as plain CSS. `@import`, rename, completion, and
diagnostics. Svelte 5's `:global { … }` block form. Three shapes are read wrongly: a
trailing nesting selector such as `.b &`, which the CSS grammar misparses; Svelte 5's
`:global` modifier, as in `.a :global .b`; and the legacy `<svelte:component>` and
`<svelte:self>` tags, which are not treated as components.

## Layout

| File | Purpose |
| --- | --- |
| `init.lua` | `setup()`: registers and enables the `svelte_css` LSP config |
| `server.lua` | The in-process server: file listing, reading, caching, request handlers |
| `resolve.lua` | Svelte's scoping over parsed files: what is under the cursor, its rules, its uses |
| `parse.lua` | Class definitions and uses from a component's or stylesheet's text |

Tests live in `tests/svelte-css/`.
