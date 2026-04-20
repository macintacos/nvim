-- github.com/rmagatti/auto-session
-- Automatic session save/restore per directory
vim.pack.add({ "https://github.com/rmagatti/auto-session" })
require("auto-session").setup({
  suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
  pre_save_cmds = { require("helpers.windows").close_all_floating_wins },
})
