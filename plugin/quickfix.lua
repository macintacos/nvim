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

-- Make <CR> close the quickfix window after jumping (e.g. picking a result
-- from `gr` LSP references). bqf maps <CR> to open(false) (jump, keep qf open)
-- when it attaches to each qf buffer during its after/ftplugin bootstrap; we
-- repoint it at open(true), which jumps AND closes the window. Deferred with
-- vim.schedule so this runs after bqf's mapping for the buffer is in place.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function(ev)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      vim.keymap.set("n", "<CR>", function()
        require("bqf.qfwin.handler").open(true)
      end, { buffer = ev.buf, nowait = true, desc = "Open item and close quickfix" })
    end)
  end,
})
