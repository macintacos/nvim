# pack-pr

`:PackPR` — pick an open PR across a configurable set of GitHub repos and point the matching `vim.pack` plugin spec at that PR's branch, so you can smoke-test a PR branch in your real config before merging. Built around an extensible repo registry where onboarding a repo is a one-line entry.

## What it does

Running `:PackPR`:

1. Runs `gh pr list` (JSON) against each repo in the registry and aggregates the open PRs.
2. Opens a snacks picker listing every PR (repo, number, title, branch, author) with fuzzy filter.
3. On selection, rewrites the repo's `vim.pack` spec file so the plugin tracks the PR branch (`{ src = ..., version = "<branch>" }`) and refreshes it with `vim.pack.update`.

Each managed repo also gets a **"reset … → default branch"** entry in the picker, which rewrites the spec back to its bare-string (default-branch) form — the point is temporary testing, so there's always a clear way back.

## Registry

The registry is configured in `plugin/pack-pr.lua`. Each entry is a bare `"owner/repo"` string, or a table that overrides a derived field:

```lua
require("plugins.pack-pr").setup({
  repos = {
    "macintacos/agentcomplete.nvim",                            -- src/name/spec_file derived
    { repo = "owner/x.nvim", spec_file = "plugin/custom.lua" },  -- override a derived field
  },
})
```

From a bare `"owner/repo"` entry the remaining fields are derived:

| Field | Derived from `repo` |
|---|---|
| `src` | `https://github.com/<repo>` |
| `name` | the URL basename (the `vim.pack` plugin name passed to `vim.pack.update`) |
| `spec_file` | `plugin/<basename without .nvim/.vim>.lua` |

Onboarding a repo is a one-line addition to the `repos` list; pass a table only when a derived field is wrong.

## Requirements

An authenticated `gh` on `PATH`. If `gh` is missing or unauthenticated, or a repo has no open PRs, `:PackPR` reports it via a notification rather than failing.

## Tests

`tests/pack-pr/` covers the pure logic — registry derivation (`registry_spec`), PR parsing and `gh` aggregation (`prs_spec`), spec rewriting (`spec_spec`) — plus the picker item-building and an integration test for the spec-file round-trip (`picker_spec`) and the command wiring (`init_spec`). Run with `mise run test`.
