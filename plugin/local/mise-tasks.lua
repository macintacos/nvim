-- Local plugin (no upstream repo)
-- <leader>pt picks one of the project's mise tasks and runs it in a floating Rex pane.
local map = require("helpers.mappings").map

map("Mise Tasks", "n", "<leader>pt", function()
  require("plugins.mise-tasks").pick()
end)
