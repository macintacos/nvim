---Builds 'statuscolumn' out of the number, sign, and fold columns.
---@see https://github.com/nvim-mini/mini.statuscolumn/blob/main/doc/mini-statuscolumn.txt
-- In beta with no stable tag yet — tracks main.
vim.pack.add({ "https://github.com/nvim-mini/mini.statuscolumn" })

-- Replaces snacks.statuscolumn, which plugin/snacks.lua disables.
require("mini.statuscolumn").setup()

-- dim_inactive rewrites CursorLineNr to MiniStatuscolumnDimCursor in every
-- unfocused window, and that group defaults to the flat MiniStatuscolumnDim, so
-- an unfocused window's cursor line loses its number highlight. Point it back at
-- CursorLineNr: the other lines stay dimmed, the cursor line stays readable.
local function set_statuscolumn_hl()
  vim.api.nvim_set_hl(0, "MiniStatuscolumnDimCursor", { link = "CursorLineNr" })
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups and
-- mini.statuscolumn's own ColorScheme handler then restores its default link.
-- Registered after setup() so it runs after that handler.
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statuscolumn_hl })

set_statuscolumn_hl()
