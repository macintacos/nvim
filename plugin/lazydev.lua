-- github.com/folke/lazydev.nvim
-- Provides Neovim API type definitions and completions for Lua files
vim.pack.add({ "https://github.com/folke/lazydev.nvim" }, { load = false })

-- Load when first opening a Lua file so the LSP picks up Neovim types
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  once = true,
  callback = function()
    vim.cmd.packadd("lazydev.nvim")
    require("lazydev").setup({
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    })
  end,
})
