-- github.com/gbprod/cutlass.nvim
-- Better cutting and pasting

---@module "lazy"
---@type LazySpec
return {
  "gbprod/cutlass.nvim",
  opts = {
    cut_key = "m",
    override_del = true,
    exclude = {},
    registers = {
      select = "_",
      delete = "_",
      change = "_",
    },
  },
}
