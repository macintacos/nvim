# go-folds

Draws Go's short constructs on one line when a Go file opens, the way GoLand's "fold by
default" does. The buffer never changes. Each construct is an ordinary closed fold whose
text is the code itself:

```go
if err != nil {
	return err
}
```

draws as `if err != nil { return err }`, followed by a fold chevron.

## What folds

- An `if` with no `else` whose block is one single-line statement.
- A function, method, or function literal whose body is one single-line `return`.
- A `case` or `default` clause whose body is one single-line statement, in a `switch`,
  a type switch, or a `select`.

A construct stays expanded when its one line would lose something or read badly:

- its block holds a comment;
- its header or its statement spans lines;
- it is an `else if`;
- its one line would pass column 100, where the fold bar also stops, or the window's
  width.

## The collapsed line

The line keeps the code's tree-sitter colors and sits on the editor's background, not on
the band a fold bar takes. Two marks say it is a fold: the chevron in the gutter, and the
same chevron after the code, in the fold bar's text color. Errors and warnings on the
hidden lines show as counts after the chevron, each behind its sign and in its diagnostic
color.

Every other closed fold in a Go window keeps the bar from `lua/config/folds.lua`,
the import block included.

## Keys

The fold keys work as on any fold: `zo` shows the construct's real lines, and `zc` draws
it on one line again.

## When constructs close

Constructs close once per buffer, when gopls's first folding ranges arrive. After that
nothing closes one for you: a construct you open stays open, and one you type stays
expanded until you close it with `zc`.

Without gopls nothing closes on open. The window then folds by tree-sitter, which folds an
`if` or a function but not a case clause, so `zc` still draws those two on one line.

## How it works

`inline.lua` decides which constructs qualify from the syntax tree alone, so the specs
test it without a window.

gopls ends a block's folding range on the line before its closing brace, so a fold made
from it would leave a `}` under the collapsed line. `init.lua` replaces each construct's
range with one that reaches the brace, through `require("config.folds").rewrite_ranges`.
The window's `'foldtext'` then draws a closed fold as code when its lines are exactly a
construct's, and falls back to the bar otherwise.

The collapsed line takes its colors from Go's tree-sitter highlights query. It doesn't
show LSP semantic-token colors or colors from languages injected into strings.

## Setup

Wired up in `plugin/local/go-folds.lua`. `setup()` takes no options. The cue's color is
the `GoFoldsCue` highlight group, set in `lua/config/highlights.lua`.

## Tests

`tests/go-folds/inline_spec.lua` covers which constructs qualify and each rule that
leaves one expanded. `tests/go-folds/init_spec.lua` covers the collapsed line's text and
colors, and closing by a language server's ranges. Run them with
`mise run test tests/go-folds`.
