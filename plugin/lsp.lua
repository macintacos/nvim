-- LSP configuration, keymaps, and tool installation via Mason
vim.pack.add({
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/neovim/nvim-lspconfig",
})

-- LSP keymaps
local map = vim.keymap.set
local function noremap(desc)
  return { noremap = true, silent = true, desc = desc }
end

map("n", "gd", vim.lsp.buf.definition, noremap("Goto Definition"))
map("n", "gD", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, noremap("Goto Definition in Split"))
map("n", "gh", function()
  vim.lsp.buf.hover({ border = "rounded", max_width = 80 })
end, noremap("Show Hover"))
map("n", "gr", vim.lsp.buf.references, noremap("Goto References"))
map("n", "gi", vim.lsp.buf.implementation, noremap("Goto Implementation"))
map("n", "gy", vim.lsp.buf.type_definition, noremap("Goto T[y]pe Definition"))
map("i", "<C-k>", function()
  vim.lsp.buf.signature_help({ border = "rounded", max_width = 80 })
end, noremap("Show Signature Help"))

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

vim.lsp.enable({ "basedpyright", "bashls", "jsonnet_ls", "lua_ls", "taplo", "ty" })

-- Mason
require("mason").setup({
  ensure_installed = {
    "basedpyright",
    "bash-language-server",
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
require("mason-lspconfig").setup()
