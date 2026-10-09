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
  -- The changeset sidebar hides its cursor, which a trail would still trace row to row.
  filetypes_disabled = { "changeset" },
})

-- The fox's bg1, which is Ghostty's background. The fox runs transparent, so
-- 'Normal' has no bg and the plugin's own fallback (#303030) would wash out the
-- dim end of the smear's gradient.
local function sync_smear_background()
  smear.transparent_bg_fallback_color = select(2, require("helpers.palette").active()).bg1
end

-- A 'background' flip reloads the colorscheme, so this follows the appearance.
vim.api.nvim_create_autocmd("ColorScheme", { callback = sync_smear_background })

sync_smear_background()

-- modes.nvim relinks 'Cursor' on every mode change (plugin/modes.lua), so the
-- smear tracks the mode by reading that group back -- already lifted clear of
-- the background there, which a thin trail needs even more than the cursor does.
local function sync_smear_color()
  local bg = vim.api.nvim_get_hl(0, { name = "Cursor", link = false }).bg
  if bg then
    smear.cursor_color = ("#%06x"):format(bg)
  end
end

-- Runs after modes.nvim's own handlers for these events -- its plugin file is
-- sourced first, and autocmds fire in registration order -- so 'Cursor'
-- already points at the new mode's group by the time this reads it.
vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme" }, { callback = sync_smear_color })

sync_smear_color()

-- Pauses the smear while a mini.pick picker is open. The picker reads keys in a
-- blocking getcharstr(), during which Neovim doesn't redraw, and the smear only
-- forces a redraw in cmdline mode -- so its frames stick on screen. FileType
-- fires synchronously while the picker builds, in time to cancel the smear its
-- opening key queued; MiniPickStart is scheduled and runs too late.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "minipick",
  callback = function()
    smear.enabled = false
  end,
})

-- Resumes the smear as the picker closes.
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniPickStop",
  callback = function()
    smear.enabled = true
  end,
})
