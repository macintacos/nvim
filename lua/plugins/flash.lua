-- github.com/folke/flash.nvim
-- Move around your buffers

---@module "lazy"
---@type LazySpec
return {
  "folke/flash.nvim",
  keys = {
    { "S", mode = { "n", "x", "o", "v" }, false },
  },
}
