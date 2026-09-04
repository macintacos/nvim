---Provides the `vim.ui.input()` implementation (snacks.input is disabled).
---@see https://github.com/nvim-mini/mini.input/blob/main/doc/mini-input.txt
-- In beta with no stable tag yet — tracks main.
vim.pack.add({ "https://github.com/nvim-mini/mini.input" })

require("mini.input").setup()
