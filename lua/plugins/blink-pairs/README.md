# blink-pairs

Rules for [blink.pairs](https://github.com/Saghen/blink.pairs) that pair Markdown emphasis and tags, and make every symmetric delimiter close an open span instead of opening a new pair.

## What it does

- **Symmetric delimiters close their span.** blink.pairs' parser tracks distinct opening and closing tokens, so it can't tell whether a symmetric delimiter (`` ` `` `"` `'` `$` `_` `*`) is unmatched, and typing `` ` `` at the end of `` `foo `` opens a new pair. `balanced(char)` counts that delimiter left of the cursor, skipping escaped characters. An odd count means a span is open, so the key closes it.
- **Markdown emphasis pairs.** blink.pairs ships `*` and `_` rules for Typst only, and no `~` rule. `md_rules` adds all three for `markdown` and `markdown_inline`. They don't pair inside an inline code span, and their count skips delimiters inside one. `_` pairs only at a word boundary, because Markdown reads `foo_bar` as a literal underscore. Typing a delimiter twice gives `**bold**` or `~~strike~~`, because the second key lands on the closer and steps over it.
- **Markdown tags pair.** `md_tag_rules` pairs `<>` for inline HTML and autolinks, and completes `<!--` with `--`, so the `>` the `<` pair left behind closes the comment.
- **Emphasis bypasses the engine's parser.** blink.pairs' Rust parser misreads an intraword `_` inside a code span, such as `non_top100`, as an unterminated italic, and closes instead of opening. `wrap_open_or_close()` wraps blink.pairs' open-or-close handler so the Markdown emphasis rules decide locally. Every other rule goes to the original handler.

## Setup

No `setup()`. `plugin/blink.lua` wires the module into blink.pairs:

1. Before blink.pairs' `setup()`, it attaches `balanced()` to every single-character symmetric rule in blink.pairs' default mapping schema, then appends `md_rules` and `md_tag_rules`.
2. After `setup()`, it replaces `ops.open_or_close_pair` with `wrap_open_or_close(ops.open_or_close_pair)`.
