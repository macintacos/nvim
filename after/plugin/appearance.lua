-- This file is added in `after/plugin` because the colorscheme should only be called ater the setup is complete.
-- Use this file to make minor changes to the appearance of neovim, unrelated to any particular plugin

vim.opt.background = "dark" -- set this to dark or light

-- Theme
vim.cmd.colorscheme("catppuccin")

-- Nightfox palette: https://github.com/EdenEast/nightfox.nvim/blob/main/lua/nightfox/palette/nightfox.lua
local hi = vim.api.nvim_set_hl
local palette = require("catppuccin.palettes").get_palette("mocha")

-- Window Borders
hi(0, "VertSplit", { fg = palette.sel0 })

-- Background
hi(0, "Normal", { bg = "#10121E" })
hi(0, "NonText", { bg = "#10121E" })
