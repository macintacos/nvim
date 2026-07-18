-- LSP configuration, keymaps, and tool installation via Mason
vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/neovim/nvim-lspconfig",
})

-- LSP keymaps
local map = require("helpers.mappings").map

-- If the cursor is on a URL, open it in the browser; otherwise go to definition
map("Goto Definition / Open URL", "n", "gd", function()
  local word = vim.fn.expand("<cWORD>")
  local url = word:match("(https?://[%w_.~!*'();:@&=+$,/?#%%[%]%-]+)")
  if url then
    vim.ui.open(url)
  else
    vim.lsp.buf.definition()
  end
end, { silent = true })
map("Goto Definition in Split", "n", "gD", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, { silent = true })
-- open_floating_preview has no native min_width. Teach it one: when a caller
-- sets opts.min_width, floor the computed width there (still capped by max_width
-- and the screen). The hover mapping below uses it so a short popup — e.g. a
-- one-line Tailwind class — isn't cramped. No-op for callers that don't set it,
-- so signature help and diagnostic floats are unaffected.
local orig_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  if opts.min_width and not opts.width and type(contents) == "table" then
    local w = 0
    for _, line in ipairs(contents) do
      w = math.max(w, vim.fn.strdisplaywidth((line:gsub("%z", "\n"))))
    end
    opts.width = math.max(w, opts.min_width)
  end
  return orig_open_floating_preview(contents, syntax, opts, ...)
end

map("Show Hover", "n", "gh", function()
  vim.lsp.buf.hover({ border = "rounded", max_width = 80, min_width = 40 })
end, { silent = true })
map("Goto References", "n", "gr", vim.lsp.buf.references, { silent = true })
map("Goto Implementation", "n", "gi", vim.lsp.buf.implementation, { silent = true })
map("Goto T[y]pe Definition", "n", "gy", vim.lsp.buf.type_definition, { silent = true })
map("Show Signature Help", "i", "<C-k>", function()
  vim.lsp.buf.signature_help({ border = "rounded", max_width = 80 })
end, { silent = true })

-- LSP server configs
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      completion = { callSnippet = "Replace" },
      hint = { enable = true },
    },
  },
})

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = {
        {
          fileMatch = { "**/.project-meta.json" },
          url = "file://" .. vim.fn.stdpath("config") .. "/schemas/project-meta.json",
        },
      },
      validate = { enable = true },
    },
  },
})

vim.lsp.config("ty", {
  cmd = { "uvx", "ty", "server" },
})

vim.lsp.config("xonsh_language_server", {
  cmd = { "xonsh-language-server" },
  filetypes = { "xonsh" },
})

-- vtsls: load the Svelte TypeScript plugin so go-to-definition and references
-- cross the .ts <-> .svelte boundary (in-file nav works without it via the
-- Svelte LSP). The plugin ships bundled inside the Mason svelte-language-server
-- package; enableForWorkspaceTypeScriptVersions runs it against the project's
-- own TypeScript rather than the one vtsls bundles.
vim.lsp.config("vtsls", {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "typescript-svelte-plugin",
            location = vim.fn.stdpath("data")
              .. "/mason/packages/svelte-language-server/node_modules/typescript-svelte-plugin",
            enableForWorkspaceTypeScriptVersions = true,
          },
        },
      },
    },
  },
})

-- mq ships no filetype plugin, so register .mq ourselves; without it the
-- buffer never gets filetype=mq and the LSP below has nothing to attach to.
vim.filetype.add({ extension = { mq = "mq" } })

-- Zed's JSON config (keymap.json, settings.json) is really JSONC — it has
-- // comments. Force jsonc so jsonls tolerates them instead of erroring.
-- Pattern matches both the chezmoi source (dot_config/zed/...) and the
-- deployed ~/.config/zed/... path.
vim.filetype.add({ pattern = { [".*/zed/.*%.json"] = "jsonc" } })

-- mq-lsp is a standalone stdio server (cargo install mq-lsp); not on Mason.
vim.lsp.config("mq", {
  cmd = { "mq-lsp" },
  filetypes = { "mq" },
  root_markers = { ".git" },
})

vim.lsp.enable({
  "bashls",
  "gopls",
  "jsonls",
  "just",
  "lua_ls",
  "mq",
  -- rumdl: Markdown lint/format LSP. Binary comes from mise (not Mason), so it
  -- is absent from ensure_installed below. Uses nvim-lspconfig's shipped config
  -- and auto-discovers .rumdl.toml.
  "rumdl",
  "svelte",
  "tailwindcss",
  "taplo",
  "ty",
  -- vimdoc_ls: LSP for vim help files (diagnostics, hover, completion). Binary
  -- comes from cargo (cargo install vimdoc-language-server), not Mason;
  -- formatting goes through conform (plugin/conform.lua), mirroring rumdl.
  "vimdoc_ls",
  "vtsls",
  "xonsh_language_server",
})

-- Mason
require("mason").setup({})
require("mason-lspconfig").setup({ automatic_enable = false })
require("mason-tool-installer").setup({
  ensure_installed = {
    "bash-language-server",
    "json-lsp",
    "just-lsp",
    "lua-language-server",
    "ruff",
    "rust-analyzer",
    "selene",
    "shellcheck",
    "shfmt",
    "stylua",
    "svelte-language-server",
    "tailwindcss-language-server",
    "taplo",
    "vtsls",
    "yamlfmt",
  },
  run_on_start = true,
})
