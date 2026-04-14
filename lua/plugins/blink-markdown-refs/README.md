# blink-markdown-refs

A [blink.cmp](https://github.com/Saghen/blink.cmp) completion source for referencing files, headings, and content across projects in markdown files.

## What it does

Type `@` in a markdown file to trigger completions:

- `@query` -- search files, headings, and content in the current project
- `@file#heading` -- search headings within files matching "file"
- `@#heading` -- search all headings matching "heading"
- `@!` -- pick a named project to search in
- `@!project@query` -- search within a specific project

When you accept a completion from a project search (`@!project@file.txt`), the `!project@` routing prefix is stripped, leaving a clean `@file.txt` reference.

## Setup

```lua
require("plugins.blink-markdown-refs").setup({
  -- Directories to scan for subdirectories
  paths = {
    "/path/to/projects",
  },
  -- Explicit entries: name = path
  projects = {
    notes = "~/notes",
  },
})
```

Then register as a blink.cmp source:

```lua
require("blink.cmp").setup({
  sources = {
    per_filetype = {
      markdown = { "markdown-refs", "lsp", "path" },
    },
    providers = {
      ["markdown-refs"] = {
        name = "MarkdownRefs",
        module = "plugins.blink-markdown-refs",
        score_offset = 200,
        async = true,
        timeout_ms = 3000,
      },
    },
  },
})
```

## Configuration

### `paths`

An array of parent directories to scan. Each directory's immediate subdirectories become project entries, using the subdirectory name as the project name.

### `projects`

A dictionary of explicit `name = "/path"` entries. Explicit entries take precedence over glob-discovered entries with the same name.

Projects appear in the completion menu when you type `@!`. The list is ordered by most recently used.

## Special keymaps

- **Shift+Enter**: Accept a completion but strip the leading `@`, inserting just the raw path.
