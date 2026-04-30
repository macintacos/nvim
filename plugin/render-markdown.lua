-- github.com/MeanderingProgrammer/render-markdown.nvim
-- Render markdown in-buffer; configured for pipe tables only.
vim.pack.add({ "https://github.com/MeanderingProgrammer/render-markdown.nvim" })

require("render-markdown").setup({
  -- All non-table components disabled.
  -- To re-enable any of these, flip `enabled = true`.
  heading = { enabled = false },
  dash = { enabled = false },
  bullet = { enabled = false },
  checkbox = { enabled = false },
  quote = { enabled = false },
  link = { enabled = false },
  sign = { enabled = false },
  indent = { enabled = false },
  html = { enabled = false },
  latex = { enabled = false },

  -- Active features
  code = {
    enabled = true,

    width = "block",
    border = "thin",
    left_pad = 3,
    right_pad = 60,
    language_pad = 2,
    background_inset = 0,
  },
  pipe_table = { enabled = true },
})
