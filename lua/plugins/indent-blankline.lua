-- Highlights indentation in code
local highlight = { "CursorColumn", "Whitespace" }

return {
  "lukas-reineke/indent-blankline.nvim",
  opts = {
    indent = {
      highlight = highlight,
      char = "",
    },
    whitespace = {
      highlight = highlight,
      remove_blankline_trail = false,
    },
  },
}
