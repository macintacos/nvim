-- github.com/EdenEast/nightfox.nvim
-- Duskfox and Dawnfox colour schemes, retuned for contrast
vim.pack.add({ "https://github.com/EdenEast/nightfox.nvim" })

local overrides = require("helpers.palette").overrides(require("helpers.palette").PATH)

require("nightfox").setup({
  options = { transparent = true },
  palettes = overrides.palettes,
  specs = overrides.specs,
  groups = {
    all = {
      NormalFloat = { bg = "NONE" },
      FloatBorder = { bg = "NONE" },
      Pmenu = { bg = "NONE" },
      PmenuSel = { fg = "fg1", bg = "sel1" },
      BlinkCmpMenu = { bg = "NONE" },
      BlinkCmpDoc = { bg = "NONE" },
    },
  },
})

vim.cmd.colorscheme("fox")
