---Extra pickers for mini.pick — lsp, keymaps, manpages, git_commits, and more —
---reachable as `:Pick <name>`.
---@see https://github.com/nvim-mini/mini.extra/blob/main/doc/mini-extra.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.extra", version = "stable" } })

-- Registration into MiniPick.registry is mutual — whichever of MiniExtra.setup()
-- and MiniPick.setup() runs second wires the pickers up — so this file and
-- plugin/mini/pick.lua may be sourced in either order.
require("mini.extra").setup()
