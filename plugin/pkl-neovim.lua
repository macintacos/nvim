-- github.com/apple/pkl-neovim
-- Pkl language support: snippets, queries, and Pkl LSP integration
vim.pack.add({ "https://github.com/apple/pkl-neovim" }, { load = false })

-- pkl-neovim ships ftdetect/pkl.vim, but lazy-loading keeps that file off the
-- runtimepath until packadd. Register filetype mappings ourselves so the
-- FileType autocmd below can actually fire when a Pkl buffer opens.
vim.filetype.add({
  extension = { pkl = "pkl", pcf = "pkl" },
  filename = { PklProject = "pkl" },
})

-- pkl-neovim is configured via the global vim.g.pkl_neovim, which its
-- ftplugin reads when start_lsp() runs. Set this BEFORE the packadd below.
-- pkl-lsp comes from homebrew; pkl is mise-managed, so use the shim so it
-- resolves to whichever pkl version mise currently has active.
vim.g.pkl_neovim = {
  start_command = { "pkl-lsp" },
  pkl_cli_path = vim.fn.expand("~/.local/share/mise/shims/pkl"),
}

-- pkl-neovim ships an ftplugin that starts the LSP the moment it loads, so
-- packadd it the first time a Pkl buffer appears, then re-fire FileType so
-- the just-loaded ftplugin runs against this buffer.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "pkl",
  once = true,
  callback = function()
    vim.cmd.packadd("pkl-neovim")
    vim.api.nvim_exec_autocmds("FileType", { pattern = "pkl" })
  end,
})
