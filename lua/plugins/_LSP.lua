-- LSP-specific Keymaps

local map = vim.keymap.set
local function noremap(desc)
  return { noremap = true, silent = true, desc = desc }
end

map("n", "gd", vim.lsp.buf.definition, noremap("Goto Definition"))
map("n", "gD", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, noremap("Goto Definition in Split"))
map("n", "gh", vim.lsp.buf.hover, noremap("Show Hover"))
map("n", "gr", vim.lsp.buf.references, noremap("Goto References"))
map("n", "gi", vim.lsp.buf.implementation, noremap("Goto Implementation"))
map("n", "gy", vim.lsp.buf.type_definition, noremap("Goto T[y]pe Definition"))
map("i", "<C-k>", vim.lsp.buf.signature_help, noremap("Show Signature Help"))

-- LSP config for languages
vim.lsp.config("jsonnet_ls", {
  -- Ref: https://github.com/grafana/jsonnet-language-server/tree/main/editor/vim
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

vim.lsp.enable({
  "bashls",
  "jsonnet_ls",
  "lua_ls",
  "taplo",
})

---@module "lazy"
---@type LazySpec
return {
  "mason-org/mason-lspconfig.nvim",
  opts = {},
  dependencies = {
    {
      "mason-org/mason.nvim",
      opts = {
        ensure_installed = {
          "bash-language-server",
          "jsonnet-language-server",
          "lua-language-server",
          "markdownlint-cli2",
          "selene",
          "shellcheck",
          "shfmt",
          "stylua",
          "taplo",
          "yamlfmt",
        },
      },
    },
    "neovim/nvim-lspconfig",
  },
}
