---Editor support for uv single-file scripts.
---
---A uv script (https://docs.astral.sh/uv/guides/scripts/) declares its dependencies
---in an inline PEP 723 block, and uv installs them into a per-script environment
---under ~/.cache/uv/environments-v2. Two things are needed to make one behave like
---ordinary Python: recognising the extensionless ones, and telling ty which
---environment to read. ty cannot discover that environment itself (astral-sh/ty#691)
---and only reads the interpreter at server start, so every script gets its own ty
---client seeded with the path uv resolves for it.
local detect = require("plugins.uv-scripts.detect")

local M = {}

---Mirrors nvim-lspconfig's markers for ty. Needed because defining `root_dir` as a
---function opts out of the `root_markers` the shipped config would otherwise apply.
---@type string[]
local ROOT_MARKERS = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }

---Build the ty client config for a script and the interpreter uv resolved for it.
---@param file string Absolute path to the script
---@param python string Absolute path to the script environment's interpreter
---@return vim.lsp.ClientConfig
function M.client_config(file, python)
  return {
    -- Named per script so two scripts sharing a directory get their own server
    -- rather than silently sharing whichever environment attached first.
    name = "ty:" .. vim.fn.fnamemodify(file, ":t"),
    cmd = { "ty", "server" },
    root_dir = vim.fs.dirname(file),
    settings = { ty = { configuration = { environment = { python = python } } } },
  }
end

---Resolve the script's uv environment and attach a ty client that knows about it.
---Re-entrant: `uv sync` is idempotent and `vim.lsp.start` reuses a matching client,
---so calling this again after a write only refreshes the installed dependencies.
---@param bufnr integer
local function attach(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" or vim.b[bufnr].uv_script_running then
    return
  end
  vim.b[bufnr].uv_script_running = true

  local function done()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.b[bufnr].uv_script_running = false
    end
  end

  vim.system({ "uv", "sync", "--script", file }, { text = true }, function(sync)
    if sync.code ~= 0 then
      vim.schedule(function()
        done()
        vim.notify("uv sync --script failed:\n" .. (sync.stderr or ""), vim.log.levels.ERROR)
      end)
      return
    end
    vim.system({ "uv", "python", "find", "--script", file }, { text = true }, function(found)
      vim.schedule(function()
        done()
        if found.code ~= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        vim.lsp.start(M.client_config(file, vim.trim(found.stdout)), { bufnr = bufnr })
      end)
    end)
  end)
end

---@param bufnr integer
local function on_python_buffer(bufnr)
  if vim.fn.executable("uv") ~= 1 or not detect.has_inline_metadata(bufnr) then
    return
  end
  -- venv-selector runs its own uv flow on these buffers and would restart the
  -- client with pyright-shaped `python.pythonPath` settings that ty ignores.
  -- Opt the buffer out and leave venv-selector to project venvs.
  vim.b[bufnr].venv_selector_disabled = true
  attach(bufnr)
end

---@param _opts? table
function M.setup(_opts)
  -- Scripts launched through a `uv run` shebang usually carry no .py extension, and
  -- Neovim's shebang table has no entry for uv, so they fall through to `conf` and
  -- get no Python tooling at all. The lowest possible priority means only files that
  -- matched no name or extension rule reach this, and detect.filetype returns nil for
  -- everything else, leaving Neovim's own content detection to run as usual.
  -- Keyed on ".+" rather than the obvious ".*": vim.filetype.add stores patterns in
  -- a table keyed by the pattern string, so two plugins choosing the same catch-all
  -- silently replace each other, and snacks.nvim's bigfile already claims ".*".
  -- ".+" matches every non-empty path just the same.
  vim.filetype.add({
    pattern = {
      [".+"] = { detect.filetype, { priority = -math.huge } },
    },
  })

  -- Keep the shared ty client off uv scripts. It would attach with no environment
  -- and, being first, own the buffer before the script client finishes resolving.
  -- Declining to call on_dir leaves the buffer without a client.
  vim.lsp.config("ty", {
    root_dir = function(bufnr, on_dir)
      if detect.has_inline_metadata(bufnr) then
        return
      end
      on_dir(vim.fs.root(bufnr, ROOT_MARKERS))
    end,
  })

  local group = vim.api.nvim_create_augroup("uv-scripts", { clear = true })

  -- Attach the script client when a uv script buffer is opened.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "python",
    desc = "Attach a uv-environment-aware ty client to PEP 723 scripts",
    callback = function(ev)
      on_python_buffer(ev.buf)
    end,
  })

  -- Re-sync on write so dependencies added to the metadata block get installed into
  -- the environment the running ty client is already reading. BufWritePost matches on
  -- file name rather than filetype, and uv scripts often have no extension, so the
  -- filetype is checked in the callback instead.
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*",
    desc = "Re-run uv sync when a PEP 723 script's dependencies change",
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "python" then
        on_python_buffer(ev.buf)
      end
    end,
  })
end

return M
