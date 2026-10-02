-- github.com/MeanderingProgrammer/render-markdown.nvim
-- Render markdown in-buffer; configured for pipe tables only.
vim.pack.add({
  "https://github.com/MeanderingProgrammer/render-markdown.nvim",

  -- Dependencies
  { src = "https://github.com/nvim-mini/mini.icons", version = "stable" },
  "https://github.com/nvim-treesitter/nvim-treesitter",
})

require("render-markdown").setup({
  -- All non-table components disabled.
  -- To re-enable any of these, flip `enabled = true`.
  dash = { enabled = false },
  checkbox = { enabled = false },
  sign = { enabled = false },
  indent = { enabled = false },
  html = { enabled = false },
  latex = { enabled = false },

  -- Active features
  bullet = { enabled = true },
  heading = { enabled = true },
  link = { enabled = true },
  pipe_table = { enabled = true },
  quote = { enabled = true },

  code = {
    enabled = true,

    width = "block",
    border = "thick",
    left_pad = 3,
    right_pad = 60,
    language_pad = 2,
    background_inset = 0,
  },
})
