-- github.com/catppuccin/nvim
-- Nice color scheme
vim.pack.add({ "https://github.com/catppuccin/nvim" })

require("catppuccin").setup({
  -- Named explicitly even though auto_integrations detects it: catppuccin's
  -- compiled-highlight cache is keyed on the options passed here, so a newly
  -- installed plugin picked up by auto-detection alone doesn't invalidate it
  -- and its groups stay unstyled until the next :CatppuccinCompile.
  integrations = { treesitter_context = true },
  transparent_background = true,
  background = { dark = "mocha" },
  float = { transparent = true, solid = false },
  -- Latte Warm: Latte on warm paper, its ink darker and its accents held to 4.6:1.
  -- Keep in sync with ghostty/themes/Catppuccin Latte Warm in the dotfiles repo,
  -- the terminal background this config shows through.
  color_overrides = {
    latte = {
      rosewater = "#a35747",
      flamingo = "#ae4e51",
      pink = "#b04095",
      mauve = "#8839ef",
      red = "#d20f39",
      maroon = "#cd2b40",
      peach = "#bc4601",
      yellow = "#9a5f00",
      green = "#207d00",
      teal = "#04787f",
      sky = "#0273a2",
      sapphire = "#00778a",
      blue = "#1961f0",
      lavender = "#5161d4",
      text = "#2e2a26",
      subtext1 = "#47433e",
      subtext0 = "#57534e",
      overlay2 = "#65615c",
      overlay1 = "#706b66",
      overlay0 = "#7d7974",
      surface2 = "#b3b0aa",
      surface1 = "#c3c0ba",
      surface0 = "#d3d0c9",
      base = "#f3f0ec",
      mantle = "#ece8e2",
      crust = "#e3e0d9",
    },
  },
})

vim.cmd.colorscheme("catppuccin-nvim")

-- Catppuccin links BlinkCmpMenu to Pmenu, which keeps a surface0 bg even when
-- transparent_background is enabled. Clear the bg so the completion popup
-- matches the terminal background like the other floats.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*",
  callback = function()
    vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "NONE" })
  end,
})
vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "NONE" })
vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "NONE" })
