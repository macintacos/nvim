-- github.com/kylechui/nvim-surround
-- Add, change, and delete surrounding pairs
vim.pack.add({ "https://github.com/kylechui/nvim-surround" }, { load = false })
vim.schedule(function()
  vim.cmd.packadd("nvim-surround")
  require("nvim-surround").setup()
end)
