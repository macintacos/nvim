-- github.com/mvllow/modes.nvim
-- Colors for the different modes on the cursorline

---@module "lazy"
---@type LazySpec
return {
  "mvllow/modes.nvim",
  opts = {
    -- Set opacity for cursorline and number background
    line_opacity = 0.30,

    -- Enable cursor highlights
    set_cursor = true,

    -- Enable cursorline initially, and disable cursorline for inactive windows
    -- or ignored filetypes
    set_cursorline = true,

    -- Enable line number highlights to match cursorline
    set_number = true,

    -- Disable modes highlights in specified filetypes
    -- Please PR commonly ignored filetypes
    ignore = { "Neotree", "TelescopePrompt" },
  },
}
