-- github.com/folke/lazydev.nvim
-- Completes require() module names for Lua files in blink.cmp
vim.pack.add({ "https://github.com/folke/lazydev.nvim" }, { load = false })

-- Set up lazydev when the first Lua buffer opens: blink's lazydev source only
-- completes require() names once lazydev's setup has run
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  once = true,
  callback = function()
    vim.cmd.packadd("lazydev.nvim")
    require("lazydev").setup({})
  end,
})
