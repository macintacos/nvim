---Filetype, LSP-kind, and directory icons, exposed as the global `MiniIcons`.
---@see https://github.com/nvim-mini/mini.icons/blob/main/doc/mini-icons.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.icons", version = "stable" } })

-- Both mini.pick and mini.extra check for the global at render time and
-- silently fall back to icon-less output when absent, so this is what puts file
-- icons on :Pick files/grep/buffers and kind icons on the LSP symbol pickers.
require("mini.icons").setup()

-- Serves the plugins that ask for nvim-web-devicons (incline, dropbar, diffview,
-- grug-far) mini.icons' icons, whose colours the colorscheme sets.
MiniIcons.mock_nvim_web_devicons()
