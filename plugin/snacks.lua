-- github.com/folke/snacks.nvim
-- UI utilities: picker, notifier, terminal, lazygit, zen mode, and more
vim.g.snacks_animate = false
vim.pack.add({ "https://github.com/folke/snacks.nvim" })

require("snacks").setup({
  bigfile = { enabled = true },
  explorer = { enabled = true, replace_netrw = false },
  -- Indent guides only — the scope line is drawn by mini.indentscope
  indent = { enabled = true, scope = { enabled = false } },
  -- vim.ui.input is handled by mini.input (see plugin/mini.lua)
  input = { enabled = false },
  image = { enabled = true },
  lazygit = { enabled = true },
  -- vim.notify is handled by mini.notify (see plugin/mini.lua)
  notifier = { enabled = false },
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
