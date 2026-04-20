-- github.com/nvim-treesitter/nvim-treesitter
-- Syntax highlighting, folds, and indentation via tree-sitter parsers
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

local ts = require("nvim-treesitter")

-- stylua: ignore start
local langs = {
  "bash",           "javascript",       "python",
  "c",              "jq",               "query",
  "diff",           "jsdoc",            "regex",
  "git_config",     "json",             "requirements",
  "git_rebase",     "json5",            "rst",
  "gitattributes",  "jsonnet",          "rust",
  "gitcommit",      "just",             "ssh_config",
  "gitignore",      "lua",              "terraform",
  "go",             "luadoc",           "toml",
  "gomod",          "luap",             "tsx",
  "gosum",          "markdown",         "typescript",
  "gotmpl",         "markdown_inline",  "vim",
  "graphql",        "nim",              "vimdoc",
  "groovy",         "printf",           "xml",
  "html",           "proto",            "yaml",
}
-- stylua: ignore end

ts.install(langs)

vim.api.nvim_create_autocmd("FileType", {
  pattern = langs,
  callback = function()
    vim.treesitter.start()
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
