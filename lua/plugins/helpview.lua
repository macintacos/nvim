-- github.com/OXY2DEV/helpview.nvim
-- Nice 'help' viewer

---@module "lazy"
---@type LazySpec
return {
  {
    "OXY2DEV/helpview.nvim",
    lazy = true,
    ft = "help",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
