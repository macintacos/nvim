---Builds 'statuscolumn' out of the number, sign, and fold columns.
---@see https://github.com/nvim-mini/mini.statuscolumn/blob/main/doc/mini-statuscolumn.txt
-- In beta with no stable tag yet — tracks main.
vim.pack.add({ "https://github.com/nvim-mini/mini.statuscolumn" })

-- Replaces snacks.statuscolumn, which plugin/snacks.lua disables.
local statuscolumn = require("mini.statuscolumn")

local wrap_mark = "%{v:lua.require'helpers.statuscolumn'.wrap_mark(v:lnum, v:virtnum)}"

-- mini's own default spec, with one change: wrapped rows draw a continuous run
-- ending in an elbow instead of repeating `↳` on every row.
--
-- The run under the cursor line asks for CursorLineNr rather than its own
-- colour so that modes.nvim reaches it: that plugin recolours per mode by
-- remapping CursorLineNr in window-local 'winhighlight', which rewrites the
-- group wherever it is drawn, statuscolumn included.
statuscolumn.setup({
  content = statuscolumn.gen_content.main({
    { format = "=lfs", sep = "▏" },
    { ltype = "virt", lnum = "•" },
    { ltype = "wrap", lnum = "%#StatuscolumnWrap#" .. wrap_mark .. "%*" },
    { pos = "cursor", ltype = "wrap", lnum = "%#CursorLineNr#" .. wrap_mark .. "%*" },
    { win = "inactive", sep = " " },
  }),
})

local function set_statuscolumn_hl()
  -- dim_inactive rewrites CursorLineNr to MiniStatuscolumnDimCursor in every
  -- unfocused window, and that group defaults to the flat MiniStatuscolumnDim, so
  -- an unfocused window's cursor line loses its number highlight. Point it back at
  -- CursorLineNr: the other lines stay dimmed, the cursor line stays readable.
  vim.api.nvim_set_hl(0, "MiniStatuscolumnDimCursor", { link = "CursorLineNr" })

  -- One palette step below LineNr's surface1, so the run down a wrapped line
  -- reads quieter than the numbers it hangs off.
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if ok then
    vim.api.nvim_set_hl(0, "StatuscolumnWrap", { fg = palettes.get_palette().surface0 })
  end
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups and
-- mini.statuscolumn's own ColorScheme handler then restores its default link.
-- Registered after setup() so it runs after that handler.
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statuscolumn_hl })

set_statuscolumn_hl()
