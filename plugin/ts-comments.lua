-- github.com/folke/ts-comments.nvim
-- Sets commentstring based on treesitter context (e.g. JSX, Vue)
vim.pack.add({ "https://github.com/folke/ts-comments.nvim" }, { load = false })
vim.schedule(function()
  vim.cmd.packadd("ts-comments.nvim")
  require("ts-comments").setup()
end)
