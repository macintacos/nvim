-- github.com/mrcjkb/rustaceanvim
-- rust-analyzer wrapper with extra Rust UX (lazy-loaded on FileType rust)
vim.pack.add({ "https://github.com/mrcjkb/rustaceanvim" }, { load = false })

-- rustaceanvim is configured via the global vim.g.rustaceanvim, which it
-- reads when its ftplugin first runs. Set this BEFORE the packadd below.
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        check = { command = "clippy" },
      },
    },
  },
}

-- rustaceanvim ships an ftplugin that wires up rust-analyzer the moment
-- it loads, so packadd it the first time a Rust buffer appears, then
-- re-fire FileType so the just-loaded ftplugin runs against this buffer.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  once = true,
  callback = function()
    vim.cmd.packadd("rustaceanvim")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "rust" })
  end,
})
