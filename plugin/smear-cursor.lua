-- github.com/sphamba/smear-cursor.nvim
-- Animates a trail behind the cursor when it jumps
vim.pack.add({ "https://github.com/sphamba/smear-cursor.nvim" })

local smear = require("smear_cursor")

smear.setup({
  -- A notch above the defaults (0.6 / 0.45 / 0.85 / 0.1): head and tail both
  -- catch up sooner and the animation gives up earlier, so the trail is
  -- shorter and settles faster.
  stiffness = 0.7,
  trailing_stiffness = 0.55,
  damping = 0.9,
  distance_stop_animating = 0.3,
  -- Ghostty's background. catppuccin runs transparent, so 'Normal' has no bg
  -- and the plugin's own fallback (#303030) would wash out the dim end of the
  -- smear's gradient.
  transparent_bg_fallback_color = "#11121d",
})

-- modes.nvim relinks 'Cursor' on every mode change (plugin/modes.lua), so the
-- smear tracks the mode by reading that group back. brighten() keeps the hue
-- and lifts the lightness: the raw mode colors are tuned as cursorline fills,
-- and the darker ones (replace's #245361) read as nothing against the
-- background once drawn as a thin trail.
local brighten = require("catppuccin.utils.colors").brighten

local function sync_smear_color()
  local bg = vim.api.nvim_get_hl(0, { name = "Cursor", link = false }).bg
  if bg then
    smear.cursor_color = brighten(("#%06x"):format(bg), 0.4)
  end
end

-- Runs after modes.nvim's own handlers for these events -- its plugin file is
-- sourced first, and autocmds fire in registration order -- so 'Cursor'
-- already points at the new mode's group by the time this reads it.
vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme" }, { callback = sync_smear_color })

sync_smear_color()
