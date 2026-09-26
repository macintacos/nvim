-- github.com/chrisgrieser/nvim-recorder
-- Better macro recording with notifications
vim.pack.add({ "https://github.com/chrisgrieser/nvim-recorder" })
require("recorder").setup({
  mapping = { startStopRecording = "@" },
})
