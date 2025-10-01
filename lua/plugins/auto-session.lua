-- github.com/rmagatti/auto-session
-- Automatic session management.
--
-- We're not using persistence.nvim because it doesn't have auto-session-loading support.

---@module "lazy"
---@type LazySpec
return {
  "rmagatti/auto-session",
  lazy = false,

  ---enables autocomplete for opts
  ---@module "auto-session"
  ---@type AutoSession.Config
  opts = {
    suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    pre_save_cmds = { require("config.helpers").close_all_floating_wins }
  },
}
