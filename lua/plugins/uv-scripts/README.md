# uv-scripts

Editor support for [uv single-file scripts](https://docs.astral.sh/uv/guides/scripts/).

A uv script declares its dependencies inline in a PEP 723 block:

```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///
import httpx
```

`uv run` installs those dependencies into a per-script environment under
`~/.cache/uv/environments-v2`. Nothing in the editor knows about that environment, so
without this plugin the imports do not resolve — no hover, no go-to-definition, no
completion.

## What it does

**Filetype detection.** Scripts launched through a `uv run` shebang usually carry no
`.py` extension, and Neovim's shebang table has no entry for uv, so they fall through
to `conf` and get no Python tooling at all. A lowest-priority pattern rule claims any
otherwise-unidentified file whose first line is a `uv run` shebang, or which opens a
`# /// script` block, as `python`. Files identified by name or extension never reach
the rule, and it returns `nil` for everything else so Neovim's own content detection
still runs.

**Environment resolution.** ty cannot discover a script's environment on its own
([astral-sh/ty#691](https://github.com/astral-sh/ty/issues/691)) and only reads the
interpreter at server start — pushing `workspace/didChangeConfiguration` to a running
client has no effect. So opening a script runs:

```sh
uv sync --script <file>          # create/refresh the environment
uv python find --script <file>   # locate its interpreter
```

and starts a ty client seeded with `ty.configuration.environment.python`. The client is
named per script, so two scripts sharing a directory get their own server rather than
silently sharing whichever environment attached first. The shared project-wide `ty`
client is kept off these buffers, since it would attach without an environment and win
the buffer first.

Writing the file re-runs `uv sync`, so dependencies added to the metadata block get
installed into the environment the running client is already reading.

## Interaction with venv-selector

venv-selector has its own PEP 723 flow, but it hands the interpreter to the LSP as
`settings.python.pythonPath` — a pyright convention ty ignores — and explicitly unsets
`VIRTUAL_ENV` for uv environments. These buffers set `b:venv_selector_disabled` so the
two do not fight over the same client; venv-selector still owns project venvs.

## Layout

| File | Purpose |
| --- | --- |
| `init.lua` | `setup()`, client config, autocmds |
| `detect.lua` | Recognising uv scripts from buffer contents |

Tests live in `tests/uv-scripts/`.
