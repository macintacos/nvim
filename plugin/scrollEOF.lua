-- github.com/Aasim-A/scrollEOF.nvim
-- Allows scrolling past the end of file, matching scrolloff behavior
vim.pack.add({ "https://github.com/Aasim-A/scrollEOF.nvim" }, { load = false })

-- Load on first cursor movement so it doesn't slow down startup
vim.api.nvim_create_autocmd("CursorMoved", {
  once = true,
  callback = function()
    vim.cmd.packadd("scrollEOF.nvim")
    require("scrollEOF").setup({
      disabled_filetypes = { "minifiles" },
    })
  end,
})
