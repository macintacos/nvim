-- github.com/folke/noice.nvim
-- Replaces the default command line, messages, and popupmenu with modern UIs
vim.pack.add({
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/folke/noice.nvim",
}, { load = false })

vim.schedule(function()
  vim.cmd.packadd("nui.nvim")
  vim.cmd.packadd("noice.nvim")
  require("noice").setup({
    presets = {
      bottom_search = true,
      command_palette = true,
      lsp_doc_border = true,
    },
  })
end)
