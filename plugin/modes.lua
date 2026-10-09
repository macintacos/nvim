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

-- The cursor is painted with the raw mode color, which is picked to work as a
-- 30%-blended cursorline fill -- replace (#245361) and visual (#9745be) all but
-- vanish when they're instead drawn solid against the background. Floor the
-- HSLuv lightness instead of brightening uniformly: the hue and the already
-- legible modes are left exactly as modes.nvim set them.
local hsluv = require("catppuccin.lib.hsluv")

local MIN_CURSOR_LIGHTNESS = 65

local function lift_cursor_colors()
  for _, scene in ipairs({ "Copy", "Delete", "Change", "Format", "Insert", "Replace", "Select", "Visual" }) do
    local group = ("Modes%sCursor"):format(scene)
    local bg = vim.api.nvim_get_hl(0, { name = group }).bg
    if bg then
      local hsl = hsluv.hex_to_hsluv(("#%06x"):format(bg))
      hsl[3] = math.max(hsl[3], MIN_CURSOR_LIGHTNESS)
      vim.api.nvim_set_hl(0, group, { bg = hsluv.hsluv_to_hex(hsl) })
    end
  end
end

-- Light rebuilds the groups instead. modes.nvim blends against 'Normal', which
-- catppuccin's transparency leaves without a bg, and its light fallback is the
-- decimal 255255255 rather than 0xffffff -- a saturated teal. Latte Warm's
-- accents already read as a solid cursor, and its base is what the terminal shows.
local LIGHT_LINE_OPACITY = 0.14
local LIGHT_SELECTION_OPACITY = 0.18

local function update_hl(name, attrs)
  local current = vim.api.nvim_get_hl(0, { name = name, link = false })
  vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", current, attrs))
end

local function paint_light_modes()
  local p = require("catppuccin.palettes").get_palette()
  local blend = require("catppuccin.utils.colors").blend
  local scenes = {
    Copy = p.yellow,
    Delete = p.red,
    Change = p.red,
    Format = p.rosewater,
    Insert = p.teal,
    Replace = p.peach,
    Select = p.mauve,
    Visual = p.mauve,
  }
  for scene, color in pairs(scenes) do
    -- Visual and Select leave the line to the selection, as modes.nvim does.
    local line = (scene == "Visual" or scene == "Select") and "NONE" or blend(color, p.base, LIGHT_LINE_OPACITY)
    vim.api.nvim_set_hl(0, ("Modes%sCursorLine"):format(scene), { bg = line })
    update_hl(("Modes%sCursorLineNr"):format(scene), { fg = color, bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursorLineSign"):format(scene), { bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursorLineFold"):format(scene), { bg = line })
    vim.api.nvim_set_hl(0, ("Modes%sCursor"):format(scene), { bg = color })
    vim.api.nvim_set_hl(0, ("Modes%sModeMsg"):format(scene), { fg = color })
  end
  local selection = blend(p.mauve, p.base, LIGHT_SELECTION_OPACITY)
  vim.api.nvim_set_hl(0, "ModesVisualVisual", { bg = selection })
  vim.api.nvim_set_hl(0, "ModesSelectVisual", { bg = selection })
  vim.api.nvim_set_hl(0, "ModesReplaceVisual", { bg = blend(p.peach, p.base, LIGHT_LINE_OPACITY) })
  update_hl("ModesVisualReplaceCursorLineNr", { fg = p.peach })
end

local function paint_mode_colors()
  if vim.o.background == "light" then
    paint_light_modes()
  else
    lift_cursor_colors()
  end
end

-- modes.nvim rebuilds these groups from the raw colors on every ColorScheme,
-- which a 'background' flip fires too. Its own handler is registered by the
-- setup() call above, and autocmds fire in registration order, so this one
-- always sees the freshly rebuilt values.
vim.api.nvim_create_autocmd("ColorScheme", { callback = paint_mode_colors })

paint_mode_colors()
