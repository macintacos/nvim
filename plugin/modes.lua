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
  ignore = { "Neotree", "TelescopePrompt" },
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

-- modes.nvim rebuilds these groups from the raw colors on every ColorScheme.
-- Its own handler is registered by the setup() call above, and autocmds fire in
-- registration order, so this one always sees the freshly rebuilt values.
vim.api.nvim_create_autocmd("ColorScheme", { callback = lift_cursor_colors })

lift_cursor_colors()
