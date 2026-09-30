-- Local plugin (no upstream repo)
-- :PackPR — pick an open PR of an installed macintacos/* plugin, track its branch
-- via vim.pack (or reset to default), and restart into it to smoke-test live.
local Cmd = require("helpers.mappings").Cmd

require("plugins.pack-pr").setup({ owner = "macintacos" })

vim.keymap.set("n", "<leader>Pp", Cmd("PackPR"), { desc = "Pick Plugin PR Branch" })
