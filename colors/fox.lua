-- Dawnfox or Duskfox from 'background'. A compiled fox forces 'background' to its
-- own value, so a fox named directly would undo every appearance flip; reclaiming
-- the name makes the next flip reload this file instead.
require("nightfox.config").set_fox(require("helpers.palette").fox())
require("nightfox").load()
vim.g.colors_name = "fox"
