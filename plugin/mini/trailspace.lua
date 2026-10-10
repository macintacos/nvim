-- github.com/nvim-mini/mini.trailspace
-- Highlights trailing whitespace; `:lua MiniTrailspace.trim()` clears it.
-- Docs: https://github.com/nvim-mini/mini.trailspace/blob/main/doc/mini-trailspace.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.trailspace", version = "stable" } })

require("mini.trailspace").setup()
