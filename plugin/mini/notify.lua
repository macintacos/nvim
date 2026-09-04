---Floating notifications and LSP progress reports.
---@see https://github.com/nvim-mini/mini.notify/blob/main/doc/mini-notify.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.notify", version = "stable" } })

-- Replaces the snacks notifier, which plugin/snacks.lua disables. Notifications
-- stack up from the bottom-right, clearing the incline filename label
-- (plugin/incline.lua) that floats there: incline sits at `margin.vertical` (2)
-- + its own row above the statusline, so the notification's bottom edge lands 3
-- rows higher than the usual bottom-right placement.
require("mini.notify").setup({
  window = {
    config = function()
      local pad = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0) + 3
      return { anchor = "SE", col = vim.o.columns, row = vim.o.lines - pad }
    end,
  },
})

-- setup() only builds the notification machinery — this is what routes
-- vim.notify through it.
vim.notify = require("mini.notify").make_notify()
