-- github.com/dstein64/vim-startuptime
-- Profiles Neovim startup by running it multiple times and averaging results.
-- Lazy-loaded: installs on first run but only loads when :StartupTime is called.

vim.pack.add({ "https://github.com/dstein64/vim-startuptime" }, { load = false })

-- Register a stub :StartupTime command that loads the real plugin on first use.
-- Once invoked, the stub deletes itself, packadd's the plugin (which registers
-- the real :StartupTime), configures it, and re-executes the command.
vim.api.nvim_create_user_command("StartupTime", function(info)
  vim.api.nvim_del_user_command("StartupTime")
  vim.cmd.packadd("vim-startuptime")
  vim.g.startuptime_tries = 10
  vim.cmd("StartupTime" .. (info.bang and "!" or "") .. " " .. (info.args or ""))
end, { nargs = "*", bang = true, desc = "Lazy-loaded: vim-startuptime" })
