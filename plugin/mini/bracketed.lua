---`[`/`]` motions for buffer, comment, conflict, diagnostic, file, indent, jump,
---location, oldfile, quickfix, treesitter, undo, window, and yank targets.
---@see https://github.com/nvim-mini/mini.bracketed/blob/main/doc/mini-bracketed.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.bracketed", version = "stable" } })

require("mini.bracketed").setup()
