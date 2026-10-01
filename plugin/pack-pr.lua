-- Local plugin (no upstream repo)
-- :PackPR — pick an open PR of one of my installed plugins, install its branch via
-- vim.pack (or reset to default), and restart into it.
local Cmd = require("helpers.mappings").Cmd

require("plugins.pack-pr").setup({ owner = "macintacos" })

vim.keymap.set("n", "<leader>Pp", Cmd("PackPR"), { desc = "Pick Plugin PR Branch" })
