-- todo-comments.nvim + mkdnflow.nvim
-- Highlight TODO/FIXME comments and markdown link/list conveniences
vim.pack.add({
  "https://github.com/folke/todo-comments.nvim",
  "https://github.com/jakewvincent/mkdnflow.nvim",
})

require("todo-comments").setup()
require("mkdnflow").setup({
  mappings = {
    MkdnNewListItem = { "i", "<CR>" },
  },
})
