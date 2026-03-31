-- github.com/gbprod/cutlass.nvim
-- Separates cut and delete operations (delete no longer yanks)
vim.pack.add({ "https://github.com/gbprod/cutlass.nvim" })
require("cutlass").setup({
  cut_key = "m",
  override_del = true,
  exclude = {},
  registers = { select = "_", delete = "_", change = "_" },
})
