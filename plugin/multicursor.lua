-- github.com/jake-stewart/multicursor.nvim
-- Multiple cursor editing with visual and match-based selection
vim.pack.add({ "https://github.com/jake-stewart/multicursor.nvim" })

local mc = require("multicursor-nvim")
mc.setup()

local hl = vim.api.nvim_set_hl
hl(0, "MultiCursorCursor", { link = "Cursor" })
hl(0, "MultiCursorVisual", { link = "Visual" })
hl(0, "MultiCursorSign", { link = "SignColumn" })
hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })

local map = require("helpers.mappings").map

-- stylua: ignore start
map("Add Cursor Above", { "n", "x" }, "<C-k>", function() mc.lineAddCursor(-1) end)
map("Add Cursor Above", { "n", "x" }, "<C-S-k>", function() mc.lineAddCursor(-1) end)
map("Add Cursor Below", { "n", "x" }, "<C-j>", function() mc.lineAddCursor(1) end)
map("Add Cursor Below", { "n", "x" }, "<C-S-j>", function() mc.lineAddCursor(1) end)

map("Add Cursor to Next Match", { "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end)
map("Add Cursor to Next Match", { "n", "x" }, "gn", function() mc.matchAddCursor(1) end)
map("Add Cursor to Prev Match", { "n", "x" }, "<C-S-n>", function() mc.matchAddCursor(-1) end)
map("Add Cursor to Prev Match", { "n", "x" }, "gN", function() mc.matchAddCursor(-1) end)
map("Add Cursor to All Matches", { "n", "x" }, "gA", function() mc.matchAllAddCursors() end)

map("Multicursor mouse down", "n", "<C-leftmouse>", mc.handleMouse)
map("Multicursor mouse drag", "n", "<C-leftdrag>", mc.handleMouseDrag)
map("Multicursor mouse release", "n", "<C-leftrelease>", mc.handleMouseRelease)

map("Toggle Multicursor", { "n", "x" }, "<C-q>", mc.toggleCursor)

-- Layer maps live only while cursors are active. Keeping them under
-- <localleader>c leaves the <leader> namespace untouched, and `c` is free of
-- the other <localleader> groups (mkdnflow's n/i/d/a/p, venv-selector's v).
mc.addKeymapLayer(function(layerMap)
  layerMap({ "n", "x" }, "<left>", mc.prevCursor, { desc = "Move to Prev Cursor" })
  layerMap({ "n", "x" }, "<right>", mc.nextCursor, { desc = "Move to Next Cursor" })
  layerMap({ "n", "x" }, "<localleader>cd", mc.deleteCursor, { desc = "Delete Main Cursor" })
  layerMap({ "n", "x" }, "<localleader>ca", mc.alignCursors, { desc = "Align Cursors" })
  layerMap("n", "<Esc>", function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)
-- stylua: ignore end
