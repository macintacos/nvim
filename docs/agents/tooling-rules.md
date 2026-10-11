# Tooling rules

These rules cover the type check, linters, formatters, git hooks, and mise tasks.

## Tools and hooks

- `mise.toml` names every tool, and `mise.lock` pins their exact versions. `mise run setup` installs them, and mise's `postinstall` hook then registers the git hooks.
- `hk.pkl` defines every formatter, linter, and git hook. The `pre-commit` hook formats and lints staged files, and `pre-push` runs the type check and the test suite. `mise run format` and `mise run lint` run hk's `fix` and `check` hooks over every file.
- A new tool needs a `[tools]` entry in `mise.toml` and a step in `hk.pkl`.
- Each task is a script in `.mise/tasks/` whose `#MISE description` line is what `mise tasks` shows. A task that reads `.tests/deps` declares `#MISE depends=["deps"]`.

## Type check

- `.emmyrc.json` configures both `mise run typecheck` and the editor's emmylua_ls, so a change to it changes both. The check runs with warnings as errors.
- Its library is `$VIMRUNTIME`, the LuaCATS luassert and busted definitions, luacov, and the plugins in `.tests/deps`. The editor resolves those plugins only after `mise run deps` has run.
- Keep luassert listed before busted. busted types the global `assert` from `require("luassert")`, which emmylua resolves only against a library it has already loaded.
- Keep plenary's own luassert types excluded through its `ignoreGlobs`, because emmylua cannot read their generic aliases.
- `types/` holds `---@meta` declarations for what emmylua cannot infer from the libraries: the mini.nvim globals, the `nvim-web-devicons` module that mini.icons mocks, and luassert's call form.

## Selene

- Declare a new runtime global in `vim.yml`, the `vim` standard library that `selene.toml` reads, or selene reports it as undefined.
- Code outside `tests/` lints under `selene.toml`. Specs lint under `tests/selene.toml`, which adds busted's globals from `tests/busted.yml`.
