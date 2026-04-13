-- github.com/kevinhwang91/nvim-bqf + github.com/stevearc/quicker.nvim
-- Better quickfix window with preview and improved editing
vim.pack.add({
  "https://github.com/kevinhwang91/nvim-bqf",
  "https://github.com/stevearc/quicker.nvim",
}, { load = false })

-- Load both plugins the first time a quickfix buffer is opened
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  once = true,
  callback = function()
    vim.cmd.packadd("nvim-bqf")
    vim.cmd.packadd("quicker.nvim")
    -- bqf bootstraps during packadd (via after/ftplugin), so setup() has
    -- already run with defaults. Override the preview winblend on the
    -- singleton floatwin directly to make the preview fully opaque.
    require("bqf.preview.floatwin").winblend = 0
    require("quicker").setup()
  end,
})
