-- github.com/folke/snacks.nvim
-- UI utilities: picker, notifier, terminal, lazygit, zen mode, and more
vim.g.snacks_animate = false
vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
  bigfile = { enabled = true },
  explorer = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  image = { enabled = true },
  lazygit = { enabled = true },
  notifier = {
    enabled = true,
    style = "compact",
    top_down = false,
    margin = { top = 0, right = 1, bottom = 2 },
  },
  picker = { enabled = true },
  quickfile = { enabled = true },
  scope = { enabled = true },
  scroll = { enabled = true },
  statuscolumn = { enabled = true },
  terminal = { enabled = true },
  words = { enabled = false },
  zen = {
    enabled = true,
    show = { statusline = true },
  },
})
