-- github.com/nvim-treesitter/nvim-treesitter/tree/main
-- Treesitter for Neovim
local ts = require("nvim-treesitter")

-- Register autocmds for filetypes that need it
local langs_to_install = {
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

-- Install all the langs
ts.install(langs_to_install)

-- Register all the langs
vim.api.nvim_create_autocmd("FileType", {
  pattern = langs_to_install,
  callback = function()
    vim.treesitter.start() -- syntax highlighting
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()" -- folds
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

---@module "lazy"
---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
}
