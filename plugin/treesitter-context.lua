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
  -- Draw the divider as real characters rather than the default underline.
  -- An underline takes its colour from `guisp`, which needs a terminal that
  -- advertises Setulc; nvim runs here under TERM=xterm-256color, which does
  -- not, so the underline falls back to each cell's foreground and reads far
  -- brighter than the theme intends.
  separator = "─",
})

-- Catppuccin styles the underline that `separator` replaces, and links the
-- separator to FloatBorder (blue). Point it at the group the theme already
-- uses for dividers so the line sits at that contrast.
vim.api.nvim_set_hl(0, "TreesitterContextBottom", {})
vim.api.nvim_set_hl(0, "TreesitterContextSeparator", { link = "WinSeparator" })
