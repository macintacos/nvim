-- github.com/folke/flash.nvim
-- Jump anywhere on screen with labeled targets via 's'
vim.pack.add({ "https://github.com/folke/flash.nvim" }, { load = false })

local map = require("helpers.mappings").map

map("Flash", { "n", "x", "o" }, "s", function()
  vim.cmd.packadd("flash.nvim")
  -- Replace this stub with the real keymap
  map("Flash", { "n", "x", "o" }, "s", function()
    require("flash").jump()
  end)
  require("flash").jump()
end)
