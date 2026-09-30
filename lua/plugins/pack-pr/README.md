# pack-pr

`:PackPR` (`<leader>Pp`) picks an open PR of one of your installed plugins, installs its branch through `vim.pack`, and restarts Neovim into it, so you can try a PR in your real config before it merges. It needs an authenticated `gh` (see [Requirements](#requirements)).

## What it does

Running `:PackPR`:

1. Discovers the plugins to manage from `vim.pack` (see [Discovery](#discovery)).
2. Runs `gh pr list` (JSON) against each discovered repo and aggregates the open PRs.
3. Opens a [mini.pick](https://github.com/nvim-mini/mini.pick) picker listing every PR (repo, number, title, branch, author), with a preview of the PR's fields and URL.
4. On selection, rewrites the plugin's spec file so it tracks the PR branch (`{ src = ..., version = "<branch>" }`).
5. Installs the branch in a headless Neovim. It then checks that the plugin's `HEAD` matches `origin/<branch>`.
6. Asks whether to restart now. Yes runs `:restart`; no leaves a notification to restart later.

If the install does not reach the branch, `:PackPR` restores the spec file to its previous contents and reports an error, so the next startup does not load a broken spec.

Each managed repo also gets a **"reset … → default branch"** entry in the picker. It rewrites the spec back to its bare-string (default-branch) form, then installs it and offers the restart. A failed install restores the spec the same way.

## Discovery

`:PackPR` manages every plugin that a `vim.pack.add` call declared this session, lazy-loaded ones included, whose source is under `https://github.com/<owner>/`. `plugin/pack-pr.lua` sets `owner`. Installing a plugin under that owner is enough to make its PRs appear; there is no list to edit.

Discovery assumes the spec-file convention: the plugin `foo.nvim` is declared in `plugin/foo.lua` (the name without `.nvim`/`.vim`). A plugin declared elsewhere shows up in the picker, but selecting it reports that `plugin/<name>.lua` is missing, or that the file has no spec for the plugin's URL.

## Keymap

| Key | Mode | Action |
|---|---|---|
| `<leader>Pp` | normal | `:PackPR` |

## Requirements

An authenticated `gh` on `PATH`. If `gh` is not on `PATH`, `:PackPR` shows an error and does not open the picker. A repo whose `gh pr list` fails, for example when `gh` is not authenticated, gets a warning; the picker still opens with the other repos' PRs and every reset entry.

## Tests

`tests/pack-pr/` has one spec per module:

- `registry_spec`: discovery from `vim.pack` plugin data.
- `prs_spec`: PR parsing and `gh` aggregation.
- `spec_spec`: spec rewriting.
- `install_spec`: the headless install commands and their verification.
- `picker_spec`: picker item-building, and an integration test of the spec-file round-trip.
- `init_spec`: the command wiring.

Run them with `mise run test tests/pack-pr/`.
