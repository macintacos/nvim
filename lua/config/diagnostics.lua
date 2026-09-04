-- Nerd Font signs for the diagnostic gutter, in place of Neovim's default
-- E/W/I/H letters. Error and warning reuse the icons lua/config/folds.lua
-- draws on a closed fold, so the badge and the gutter agree.
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})
