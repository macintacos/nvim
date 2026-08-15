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
        { path = "${3rd}/busted/library" },
        { path = "${3rd}/luassert/library" },
        { path = "snacks.nvim", words = { "Snacks" } },
        -- mini.nvim modules expose their API as a global rather than a
        -- returned table, so the annotations only resolve if the module's own
        -- source is on the library path.
        { path = "mini.pick", words = { "MiniPick" } },
        { path = "mini.extra", words = { "MiniExtra" } },
        { path = "mini.icons", words = { "MiniIcons" } },
      },
    })
  end,
})
