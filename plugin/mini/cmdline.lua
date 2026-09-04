---Autocorrects misspelled commands and options, and peeks at the lines a
---`:range` refers to.
---@see https://github.com/nvim-mini/mini.cmdline/blob/main/doc/mini-cmdline.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.cmdline", version = "stable" } })

-- Autocomplete is off because blink.cmp already drives cmdline completion (see
-- plugin/blink.lua) and both would open a popup.
require("mini.cmdline").setup({
  autocomplete = { enable = false },
})
