-- LSP configuration, keymaps, and tool installation via Mason
vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim",
  "https://github.com/neovim/nvim-lspconfig",
})

-- LSP keymaps
local map = require("helpers.mappings").map
local jump_then_reveal = require("helpers.windows").jump_then_reveal

-- If the cursor is on a URL, open it in the browser; on a cyclopts lazy command's
-- import path, go to what it names; otherwise go to definition
map("Goto Definition / Open URL", "n", "gd", function()
  local url = require("helpers.links").url(tostring(vim.fn.expand("<cWORD>")))
  if url then
    return vim.ui.open(url)
  end
  local lazy_command = require("helpers.cyclopts").under_cursor()
  if lazy_command then
    jump_then_reveal(function()
      vim.lsp.util.show_document(lazy_command, "utf-8")
    end)
  else
    jump_then_reveal(vim.lsp.buf.definition)
  end
end, { silent = true })
map("Goto Definition in Split", "n", "gD", function()
  vim.cmd("vsplit")
  jump_then_reveal(vim.lsp.buf.definition)
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

map("Show Hover / Line Diagnostics", "n", "gh", function()
  require("helpers.hover").hover({ border = "rounded", max_width = 80, min_width = 40, anchor_bias = "above" })
end, { silent = true })
map("Goto References", "n", "grr", function()
  MiniPick.registry.lsp({ scope = "references" })
end, { silent = true })
map("Goto Implementation", "n", "gi", function()
  jump_then_reveal(vim.lsp.buf.implementation)
end, { silent = true })
map("Goto T[y]pe Definition", "n", "gy", function()
  jump_then_reveal(vim.lsp.buf.type_definition)
end, { silent = true })
map("Show Signature Help", "i", "<C-k>", function()
  vim.lsp.buf.signature_help({ border = "rounded", max_width = 80 })
end, { silent = true })

-- LSP server configs
vim.lsp.config("emmylua_ls", {
  settings = {
    emmylua = {
      diagnostics = { globals = { "vim" } },
      completion = { callSnippet = true },
      -- the runtime's LuaCATS stubs (vim.api, vim.uv): no other source supplies them to emmylua_ls
      workspace = { library = { vim.env.VIMRUNTIME .. "/lua" } },
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
  "emmylua_ls",
  -- fish_lsp: binary comes from Homebrew (brew install fish-lsp), not Mason.
  "fish_lsp",
  "gopls",
  "jsonls",
  "just",
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

-- Folds a file's import block away when it opens, so the code is what shows
-- first. Fires when a client attaches to a buffer; only a server reporting
-- folding ranges, in a language with imports, takes over the window's folds.
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("__personal_fold_imports", { clear = true }),
  callback = function(ev)
    require("config.folds").fold_imports(assert(vim.lsp.get_client_by_id(ev.data.client_id)), ev.buf)
  end,
})

-- Mason
require("mason").setup()
-- setup() deep-merges this onto its defaults, but MasonLspconfigSettings declares ensure_installed required.
---@diagnostic disable-next-line: missing-fields, param-type-mismatch
require("mason-lspconfig").setup({ automatic_enable = false })
require("mason-tool-installer").setup({
  ensure_installed = {
    "bash-language-server",
    "emmylua_ls",
    "json-lsp",
    "just-lsp",
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
