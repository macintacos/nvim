-- github.com/OXY2DEV/helpview.nvim
-- Renders :help buffers with improved formatting
vim.pack.add({ "https://github.com/OXY2DEV/helpview.nvim" }, { load = false })

-- Load when first opening a help buffer
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  once = true,
  callback = function()
    vim.cmd.packadd("helpview.nvim")
  end,
})
