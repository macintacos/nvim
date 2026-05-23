-- Local plugin (no upstream repo)
-- Provides :GoToLine — fuzzy-pick a project file then jump to a line.
require("plugins.gotoline").setup({})

local map = require("helpers.mappings").map
local Cmd = require("helpers.mappings").Cmd

map("Open the GoToLine modal", "n", "gl", Cmd("GoToLine"))
