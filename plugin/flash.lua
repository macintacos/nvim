-- github.com/folke/flash.nvim
-- Jump anywhere on screen with labeled targets via 's'
vim.pack.add({ "https://github.com/folke/flash.nvim" }, { load = false })

vim.keymap.set({ "n", "x", "o" }, "s", function()
  vim.cmd.packadd("flash.nvim")
  -- Replace this stub with the real keymap
  vim.keymap.set({ "n", "x", "o" }, "s", function()
    require("flash").jump()
  end, { desc = "Flash" })
  require("flash").jump()
end, { desc = "Flash" })
