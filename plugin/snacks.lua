-- github.com/folke/snacks.nvim
-- UI utilities: picker, notifier, terminal, lazygit, zen mode, and more
vim.g.snacks_animate = false
vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
  bigfile = { enabled = true },
  explorer = { enabled = true, replace_netrw = false },
  indent = { enabled = true },
  -- vim.ui.input is handled by mini.input (see plugin/mini.lua)
  input = { enabled = false },
  image = { enabled = true },
  lazygit = { enabled = true },
  notifier = {
    enabled = true,
    style = "compact",
    top_down = false,
    margin = { top = 0, right = 1, bottom = 2 },
  },
  picker = {
    -- Kept enabled only because snacks.explorer is a picker under the hood;
    -- the pickers themselves are mini.pick (see plugin/mini.lua).
    enabled = true,
    -- vim.ui.select is handled by mini.pick, whose setup() claims it too. This
    -- file sources after plugin/mini.lua, so without opting out snacks wins.
    ui_select = false,
  },
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
