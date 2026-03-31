-- github.com/nvim-treesitter/nvim-treesitter
-- Syntax highlighting, folds, and indentation via tree-sitter parsers
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

local ts = require("nvim-treesitter")
local langs = {
  "bash",
  "c",
  "diff",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gotmpl",
  "graphql",
  "groovy",
  "html",
  "javascript",
  "jq",
  "jsdoc",
  "json",
  "json5",
  "jsonnet",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "nim",
  "printf",
  "proto",
  "python",
  "query",
  "regex",
  "requirements",
  "rst",
  "rust",
  "ssh_config",
  "terraform",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

ts.install(langs)

vim.api.nvim_create_autocmd("FileType", {
  pattern = langs,
  callback = function()
    vim.treesitter.start()
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
