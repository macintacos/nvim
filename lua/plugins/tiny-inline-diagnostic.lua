-- github.com/rachartier/tiny-inline-diagnostic.nvim
-- Tiny inline diagnostics

---@module "lazy"
---@type LazySpec
return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup()
    vim.diagnostic.config({ virtual_text = false })
  end,
}
