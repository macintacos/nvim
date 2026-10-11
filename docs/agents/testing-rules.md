# Testing rules

These rules cover writing and running the plenary specs under `tests/`.

## Layout

- Specs mirror the code they test: `tests/<plugin>/<module>_spec.lua` for a local plugin's module, and `tests/config/` and `tests/helpers/` for `lua/config/` and `lua/helpers/`.
- Specs use busted's `describe`, `it`, `before_each`, and `after_each` blocks, and luassert's `assert`.

## Running

- Run `mise run test`, or `mise run test <path>` for one spec file or directory. Both check out `.tests/deps` first.
- Never use `:PlenaryBustedFile`, because from a worktree it tests the default checkout instead of yours. It accepts no options, so the Neovim it spawns gets no `-u` and resolves `stdpath("config")` to the default checkout.
- `mise run coverage` runs the suite under luacov and prints per-file line coverage of `lua/`.

## Isolation

- Each spec file runs in its own headless Neovim, in parallel with the others, so no state carries from one file to the next.
- `tests/minimal_init.lua` cuts specs off from the real editor's state and the real git setup, so a spec cannot rely on either. It:
  - turns off the ShaDa file and swap files;
  - points `XDG_STATE_HOME` and `XDG_CACHE_HOME` at temporary directories;
  - removes every `GIT_*` variable a git hook exports;
  - replaces the user and system git config with `/dev/null`, so a setting such as `diff.noprefix` never reaches a spec.

## Fixtures

- Shared fixtures live in `tests/support/` and load as `require("support.<name>")`, because `minimal_init.lua` puts `tests/` on `package.path`. `support.git` provides `git(args, cwd)`, `init_repo(branch, cwd)`, and `commit(message, cwd)`; use it rather than writing another git helper. `support.palette` writes a synthetic palette file whose every color is distinct.
- Every `support.git` function takes the repo to run in, so call `vim.fn.chdir` only when the code under test reads the process directory.
- Build temporary files with `vim.fn.mkdir()` and `vim.fn.writefile()` under `vim.fn.tempname()`, and delete them in `after_each`.
- A spec loads a third-party plugin from `.tests/deps` through `support.deps`: `vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))`. A plugin missing from that module's `plugins` list goes there first, per `docs/agents/plugins-rules.md`.
