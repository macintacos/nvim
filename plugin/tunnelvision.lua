-- github.com/leolaurindo/tunnelvision.nvim
-- Dims lines unrelated to the symbol under the cursor
vim.pack.add({ "https://github.com/leolaurindo/tunnelvision.nvim" }, { load = false })

-- Overrides the built-in gf (goto file). Loads the plugin on first press so it
-- doesn't slow down startup, then flips between dimmed and normal.
vim.keymap.set("n", "gf", function()
  if not package.loaded.tunnelvision then
    vim.cmd.packadd("tunnelvision.nvim")
    require("tunnelvision").setup({ mode = "dynamic" })
  end
  require("tunnelvision").toggle()
end, { desc = "Toggle TunnelVision" })
