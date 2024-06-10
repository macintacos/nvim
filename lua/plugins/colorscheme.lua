-- Use this file to contain all colorschemes and their relevant configuration settings
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = { transparent_background = true },
  },
  -- Actually set the colorscheme here.
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-mocha" } },
}
