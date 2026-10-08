# pack-updates

The statusline shows how many installed plugins have upstream commits you haven't pulled, as a plug icon followed by the count, with a braille spinner while the check runs. Run `vim.pack.update()` to review and apply them. The section is empty when every plugin is current, and hidden in windows narrower than 75 columns.

## What it checks

A plugin counts as outdated when its remote ref resolves to a different commit than the one checked out on disk. The check runs `git ls-remote` for each plugin through `vim.system()`, at most 10 at a time, so the editor stays responsive while it waits on the network. A plugin whose lookup fails, for example when you're offline, counts as current.

The check covers only the `nvim-pack-lock.json` entries whose remote ref it can name:

- An entry with no `version` is compared against the remote `HEAD`.
- An entry pinned to a branch or tag, such as `'stable'`, is compared against `refs/heads/<name>` or `refs/tags/<name>`.

The check skips entries with a semver range, such as `1.0.0 - 2.0.0`, and plugins that aren't installed yet.

The baseline is the checkout's `HEAD`, not the lockfile's `rev`. `vim.pack.update()` diffs against the checkout, and the lockfile can lag behind it, so comparing against the lockfile would count plugins that have nothing to update.

## When it checks

At startup, the check reuses the last result if it is less than 24 hours old. The module stores that result in `stdpath("cache")/pack-updates-cache.json`, and discards it early when `nvim-pack-lock.json` was modified after the cache was written.

After `vim.pack.update()` applies a batch of updates, the check runs again with the cache bypassed, so the count drops when the updates land instead of on the next startup. The module notes each `PackChanged` event of kind `update`, then re-checks on the next `vim.pack` `Progress` event with status `success`, which marks the end of a batch. It waits for that event because until the batch ends, some checkouts may not be on disk. The download batch that runs before the confirmation buffer opens also ends with `success`, but it sends no `update` events, so it doesn't trigger a re-check.

`<leader>Pc` runs a fresh check on demand, also bypassing the cache.

## Wiring

The root `init.lua` starts the check and registers the post-update re-check in a `VimEnter` autocmd. The statusline section in `plugin/mini/statusline.lua` and the `<leader>Pc` keymap in `plugin/which-key.lua` call the module directly.

| Function | Purpose | Called from |
|---|---|---|
| `check(force?)` | Starts the async check. `force` bypasses the cache. | root `init.lua`, `<leader>Pc` |
| `recheck_on_update()` | Registers the `PackChanged` and `Progress` autocmds that re-check after an update. | root `init.lua` |
| `update_count()` | Returns the number of outdated plugins. Each check restarts it at 0, so mid-check it counts only the plugins checked so far. | statusline |
| `spinner_frame()` | Returns the current spinner frame, or `nil` when no check is running. | statusline |

## Tests

`tests/pack-updates/init_spec.lua` checks three behaviors:

- The baseline is the checked-out revision when the lockfile lags it.
- A batch that updated plugins triggers exactly one forced re-check.
- A download-only batch triggers none.

Run it with `mise run test tests/pack-updates/`.
