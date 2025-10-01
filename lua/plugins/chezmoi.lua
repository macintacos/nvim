-- github.com/xvzc/chezmoi.nvim
-- Helps with managing chezmoi configurations

---@module "lazy"
---@type LazySpec
return {
  "xvzc/chezmoi.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("chezmoi").setup({})
  end,
}
