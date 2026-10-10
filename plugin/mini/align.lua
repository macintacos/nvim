-- github.com/nvim-mini/mini.align
-- Aligns text into columns with `ga`/`gA`, previewing each step as you type.
-- Docs: https://github.com/nvim-mini/mini.align/blob/main/doc/mini-align.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.align", version = "stable" } })

require("mini.align").setup()
