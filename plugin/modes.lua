-- github.com/mvllow/modes.nvim
-- Colors the cursorline based on the current mode
vim.pack.add({ "https://github.com/mvllow/modes.nvim" })
require("modes").setup({
  -- Every mode at 0.30 except visual, which is blended lighter so the selection
  -- stands out against the cursorline.
  line_opacity = {
    copy = 0.30,
    delete = 0.30,
    change = 0.30,
    format = 0.30,
    insert = 0.30,
    replace = 0.30,
    select = 0.30,
    visual = 0.45,
  },
  set_cursor = true,
  -- Left to 'cursorline' from lua/config/options.lua, which is on everywhere.
  -- modes.nvim's own management turns it off on WinLeave, which would leave
  -- unfocused windows with no marker for the line their cursor is on. Mode
  -- colors are applied through window-local 'winhighlight', so they still only
  -- reach the focused window.
  set_cursorline = false,
  set_number = true,
  -- The changeset sidebar hides its cursor through 'guicursor', and the `a:Cursor`
  -- modes.nvim appends there on entering a window would show it again.
  ignore = { "Neotree", "TelescopePrompt", "changeset" },
})

-- Rebuilds the groups from the palette rather than modes.nvim's own colours.
-- Insert, Replace and Visual match their statusline pills, and each line tint
-- blends the mode's colour into bg1, the editor background.
local LINE_OPACITY = 0.14

local function update_hl(name, attrs)
  local current = vim.api.nvim_get_hl(0, { name = name, link = false })
  vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", current, attrs))
end

local function paint_mode_colors()
  local palette = require("helpers.palette")
  local p = palette.active()
  if not p then
    return
  end
  local scenes = {
    Copy = p.yellow.base,
    Delete = p.red.base,
    Change = p.red.base,
    Format = p.orange.base,
    Insert = p.green.base,
    Replace = p.orange.base,
    Select = p.yellow.base,
    Visual = p.yellow.base,
  }
  for scene, color in pairs(scenes) do
    -- Visual and Select leave the line to the selection, as modes.nvim does.
    local line = (scene == "Visual" or scene == "Select") and "NONE" or palette.blend(p.bg1, color, LINE_OPACITY)
    vim.api.nvim_set_hl(0, ("Modes%sCursorLine"):format(scene), { bg = line })
    update_hl(("Modes%sCursorLineNr"):format(scene), { fg = color, bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursorLineSign"):format(scene), { bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursorLineFold"):format(scene), { bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursor"):format(scene), { bg = color })
    vim.api.nvim_set_hl(0, ("Modes%sModeMsg"):format(scene), { fg = color })
  end
  vim.api.nvim_set_hl(0, "ModesVisualVisual", { bg = p.sel0 })
  vim.api.nvim_set_hl(0, "ModesSelectVisual", { bg = p.sel0 })
  vim.api.nvim_set_hl(0, "ModesReplaceVisual", { bg = palette.blend(p.bg1, p.orange.base, LINE_OPACITY) })
  update_hl("ModesVisualReplaceCursorLineNr", { fg = p.orange.base })
end

-- modes.nvim rebuilds these groups from the raw colors on every ColorScheme,
-- which a 'background' flip fires too. Its own handler is registered by the
-- setup() call above, and autocmds fire in registration order, so this one
-- always sees the freshly rebuilt values.
vim.api.nvim_create_autocmd("ColorScheme", { callback = paint_mode_colors })
