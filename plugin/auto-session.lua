-- github.com/rmagatti/auto-session
-- Automatic session save/restore per directory
vim.pack.add({ "https://github.com/rmagatti/auto-session" })
require("auto-session").setup({
  suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
  pre_save_cmds = { require("helpers.windows").close_all_floating_wins },
  -- When no session is restored at startup, open the cwd's README.md (if any).
  -- Skips when nvim was launched with file args so an explicitly-opened file isn't clobbered.
  no_restore_cmds = {
    function(is_startup)
      if not is_startup then
        return
      end
      local argc = vim.fn.argc()
      local launched_in_dir = argc == 0 or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)
      if not launched_in_dir then
        return
      end
      local readme = vim.fs.joinpath(vim.fn.getcwd(), "README.md")
      if vim.fn.filereadable(readme) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(readme))
      end
    end,
  },
})
