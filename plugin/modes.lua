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

-- Rebuilds the groups from the palette. modes.nvim blends against 'Normal',
-- which transparency leaves without a bg, and its light fallback is the decimal
-- 255255255 rather than 0xffffff -- a saturated teal. The fox's accents already
-- read as a solid cursor, and its bg1 is what the terminal shows.
local LINE_OPACITY = 0.14
local SELECTION_OPACITY = 0.18

local function update_hl(name, attrs)
  local current = vim.api.nvim_get_hl(0, { name = name, link = false })
  vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", current, attrs))
end

local function paint_mode_colors()
  local palette = require("helpers.palette")
  local p, spec = palette.active()
  local scenes = {
    Copy = p.yellow.base,
    Delete = p.red.base,
    Change = p.red.base,
    Format = p.orange.dim,
    Insert = p.cyan.base,
    Replace = p.orange.base,
    Select = p.magenta.base,
    Visual = p.magenta.base,
  }
  for scene, color in pairs(scenes) do
    -- Visual and Select leave the line to the selection, as modes.nvim does.
    local line = (scene == "Visual" or scene == "Select") and "NONE" or palette.blend(spec.bg1, color, LINE_OPACITY)
    vim.api.nvim_set_hl(0, ("Modes%sCursorLine"):format(scene), { bg = line })
    update_hl(("Modes%sCursorLineNr"):format(scene), { fg = color, bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursorLineSign"):format(scene), { bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursorLineFold"):format(scene), { bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursor"):format(scene), { bg = color })
    vim.api.nvim_set_hl(0, ("Modes%sModeMsg"):format(scene), { fg = color })
  end
  local selection = palette.blend(spec.bg1, p.magenta.base, SELECTION_OPACITY)
  vim.api.nvim_set_hl(0, "ModesVisualVisual", { bg = selection })
  vim.api.nvim_set_hl(0, "ModesSelectVisual", { bg = selection })
  vim.api.nvim_set_hl(0, "ModesReplaceVisual", { bg = palette.blend(spec.bg1, p.orange.base, LINE_OPACITY) })
  update_hl("ModesVisualReplaceCursorLineNr", { fg = p.orange.base })
end

-- modes.nvim rebuilds these groups from the raw colors on every ColorScheme,
-- which a 'background' flip fires too. Its own handler is registered by the
-- setup() call above, and autocmds fire in registration order, so this one
-- always sees the freshly rebuilt values.
vim.api.nvim_create_autocmd("ColorScheme", { callback = paint_mode_colors })
