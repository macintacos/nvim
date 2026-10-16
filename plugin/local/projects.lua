-- Local plugin (no upstream repo)
-- <leader>p opens a zoxide-backed project picker; selecting one relaunches
-- Neovim in that directory (via the fish `nvim` wrapper) so you land there.
require("plugins.projects").setup()

vim.keymap.set("n", "<leader>pp", function()
  require("plugins.projects").open()
end, { desc = "Projects" })
