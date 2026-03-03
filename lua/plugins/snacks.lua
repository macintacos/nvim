vim.g.snacks_animate = false

---@module "lazy"
---@type LazySpec
return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    image = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true, top_down = false },
    picker = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    words = { enabled = true },

    zen = {
      enabled = true,
      show = { statusline = true },
    },
  },
}
