-- github.com/stevearc/quicker.nvim
-- Improvements to the quickfix menu

---@module "lazy"
---@type LazySpec
return {
  "stevearc/quicker.nvim",
  ft = "qf",
  ---@module "quicker"
  ---@type quicker.SetupOptions
  opts = {},
}
