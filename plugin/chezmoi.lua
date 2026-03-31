-- github.com/xvzc/chezmoi.nvim
-- Editing support for chezmoi-managed dotfiles
vim.pack.add({
  "https://github.com/xvzc/chezmoi.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
})
require("chezmoi").setup({})
