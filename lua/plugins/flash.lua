-- github.com/folke/flash.nvim
-- Move around your buffers

---@module "lazy"
---@type LazySpec
return {
  "folke/flash.nvim",
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o", "v" }, false },
  },
}
