-- github.com/rachartier/tiny-inline-diagnostic.nvim
-- Tiny inline diagnostics

vim.diagnostic.config({ virtual_text = false })

---@module "lazy"
---@type LazySpec
return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        options = {
          show_source = true,
          multiple_diag_under_cursor = true,
          multilines = true,
          show_all_diagns_on_cursorline = true,
        },
      })
    end,
  },
}
