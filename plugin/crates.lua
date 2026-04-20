-- github.com/saecki/crates.nvim
-- Inline info (latest version, features, vulnerabilities) in Cargo.toml
vim.pack.add({ "https://github.com/saecki/crates.nvim" }, { load = false })

-- Cargo.toml is the only file that uses this plugin. Trigger on the first
-- BufRead/BufNewFile, then re-fire the event for the triggering buffer so
-- crates.nvim's own just-registered handler attaches to it.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "Cargo.toml",
  once = true,
  callback = function(ev)
    vim.cmd.packadd("crates.nvim")
    require("crates").setup()
    vim.api.nvim_exec_autocmds(ev.event, { buffer = ev.buf, modeline = false })
  end,
})
