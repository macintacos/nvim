-- github.com/nvim-mini/mini.bracketed
-- `[`/`]` motions for buffer, comment, conflict, diagnostic, file, indent, jump,
-- location, oldfile, quickfix, treesitter, undo, window, and yank targets.
-- Docs: https://github.com/nvim-mini/mini.bracketed/blob/main/doc/mini-bracketed.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.bracketed", version = "stable" } })

-- `]c`/`[c` walk changeset's review comments (plugin/changeset.lua).
require("mini.bracketed").setup({ comment = { suffix = "" } })
