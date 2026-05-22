-- Local plugin (no upstream repo)
-- Provides :GoToLine — fuzzy-pick a project file then jump to a line.
require("plugins.gotoline").setup({})

vim.api.nvim_create_user_command("GoToLine", function()
  require("plugins.gotoline").open()
end, { desc = "Open the GoToLine modal" })
