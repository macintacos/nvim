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

local map = vim.keymap.set

-- stylua: ignore start
map({ "n", "x" }, "<C-k>", function() mc.lineAddCursor(-1) end, { desc = "Add Cursor Above" })
map({ "n", "x" }, "<C-S-k>", function() mc.lineAddCursor(-1) end, { desc = "Add Cursor Above" })
map({ "n", "x" }, "<C-j>", function() mc.lineAddCursor(1) end, { desc = "Add Cursor Below" })
map({ "n", "x" }, "<C-S-j>", function() mc.lineAddCursor(1) end, { desc = "Add Cursor Below" })

map({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "Add Cursor to Next Match" })
map({ "n", "x" }, "gn", function() mc.matchAddCursor(1) end, { desc = "Add Cursor to Next Match" })
map({ "n", "x" }, "<C-S-n>", function() mc.matchAddCursor(-1) end, { desc = "Add Cursor to Prev Match" })
map({ "n", "x" }, "gN", function() mc.matchAddCursor(-1) end, { desc = "Add Cursor to Prev Match" })
map({ "n", "x" }, "gA", function() mc.matchAllAddCursors() end, { desc = "Add Cursor to All Matches" })

map("n", "<C-leftmouse>", mc.handleMouse)
map("n", "<C-leftdrag>", mc.handleMouseDrag)
map("n", "<C-leftrelease>", mc.handleMouseRelease)

map({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Toggle Multicursor" })

mc.addKeymapLayer(function(layerMap)
  layerMap({ "n", "x" }, "<left>", mc.prevCursor, { desc = "Move to Prev Cursor" })
  layerMap({ "n", "x" }, "<right>", mc.nextCursor, { desc = "Move to Next Cursor" })
  layerMap({ "n", "x" }, "<leader>x", mc.deleteCursor, { desc = "Delete Main Cursor" })
  layerMap({ "n", "x" }, "<leader>a", mc.alignCursors, { desc = "Align Cursors" })
  layerMap("n", "<Esc>", function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)
-- stylua: ignore end
