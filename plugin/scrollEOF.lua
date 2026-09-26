-- github.com/Aasim-A/scrollEOF.nvim
-- Allows scrolling past the end of file, matching scrolloff behavior
vim.pack.add({ "https://github.com/Aasim-A/scrollEOF.nvim" }, { load = false })

-- Load on first cursor movement so it doesn't slow down startup
vim.api.nvim_create_autocmd("CursorMoved", {
  once = true,
  callback = function()
    vim.cmd.packadd("scrollEOF.nvim")
    require("scrollEOF").setup({
      -- The changeset sidebar is a list, not a file: scrolling it past its end on open
      -- pushes its first row off the top.
      disabled_filetypes = { "minifiles", "changeset" },
    })
  end,
})
