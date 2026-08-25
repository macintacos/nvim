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
