---Highlights other instances of the word under the cursor.
---@see https://github.com/nvim-mini/mini.cursorword/blob/main/doc/mini-cursorword.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.cursorword", version = "stable" } })

-- vim-illuminate (plugin/illuminate.lua) covers the same ground with
-- LSP/treesitter providers; both draw.
require("mini.cursorword").setup()
