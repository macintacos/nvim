-- github.com/rachartier/tiny-inline-diagnostic.nvim
-- Compact inline diagnostic messages replacing default virtual text
vim.pack.add({ "https://github.com/rachartier/tiny-inline-diagnostic.nvim" }, { load = false })
vim.schedule(function()
  vim.cmd.packadd("tiny-inline-diagnostic.nvim")
  require("tiny-inline-diagnostic").setup()
  vim.diagnostic.config({ virtual_text = false })
end)
