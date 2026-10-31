-- github.com/chrisgrieser/nvim-recorder
-- Better macro recording with notifications
vim.pack.add({ "https://github.com/chrisgrieser/nvim-recorder" })
-- configObj and maps require every key, but setup() deep-merges this over its defaults.
---@diagnostic disable-next-line: missing-fields, param-type-mismatch
require("recorder").setup({
  ---@diagnostic disable-next-line: missing-fields
  mapping = { startStopRecording = "@" },
  -- Its icons go into each keymap's desc; plugin/which-key.lua gives them real ones.
  useNerdfontIcons = false,
})
