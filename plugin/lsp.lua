-- LSP configuration, keymaps, and tool installation via Mason
vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
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
map("Show Hover", "n", "gh", function()
  vim.lsp.buf.hover({ border = "rounded", max_width = 80 })
end, { silent = true })
map("Goto References", "n", "gr", vim.lsp.buf.references, { silent = true })
map("Goto Implementation", "n", "gi", vim.lsp.buf.implementation, { silent = true })
map("Goto T[y]pe Definition", "n", "gy", vim.lsp.buf.type_definition, { silent = true })
map("Show Signature Help", "i", "<C-k>", function()
  vim.lsp.buf.signature_help({ border = "rounded", max_width = 80 })
end, { silent = true })

-- LSP server configs
vim.lsp.config("jsonnet_ls", {
  settings = { formatting = { StringStyle = "double" } },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      completion = { callSnippet = "Replace" },
      hint = { enable = true },
    },
  },
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "off",
      },
    },
  },
})

vim.lsp.config("ty", {
  cmd = { "uvx", "ty", "server" },
})

vim.lsp.enable({ "basedpyright", "bashls", "jsonls", "jsonnet_ls", "lua_ls", "taplo", "ty" })

-- Mason
require("mason").setup({
  ensure_installed = {
    "basedpyright",
    "bash-language-server",
    "json-lsp",
    "jsonnet-language-server",
    "lua-language-server",
    "markdownlint-cli2",
    "ruff",
    "selene",
    "shellcheck",
    "shfmt",
    "stylua",
    "taplo",
    "yamlfmt",
  },
})
require("mason-lspconfig").setup({ automatic_enable = false })
