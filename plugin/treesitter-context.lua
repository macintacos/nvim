-- github.com/nvim-treesitter/nvim-treesitter-context
-- Pins the enclosing scope (function, class, branch) to the top of the window
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter-context" })

require("treesitter-context").setup({
  -- Track the top visible line rather than the cursor, so the context follows
  -- the scroll instead of only updating when the cursor moves.
  mode = "topline",
  -- Keep the sticky header small: at most three levels of nesting, each
  -- collapsed to a single line so long signatures don't eat the window.
  max_lines = 3,
  multiline_threshold = 1,
})
