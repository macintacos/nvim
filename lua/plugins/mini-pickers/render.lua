---Shared render primitives for the symbol pickers.
---
---Both pickers annotate rows with the same vocabulary — a kind label in the
---symbol's own hue, and dim context text — so the namespace they draw into and
---the highlight groups they draw with live here.

local M = {}

M.ns = vim.api.nvim_create_namespace("mini_pick_lsp_symbols")

-- Subdued italic labels for the right-aligned kind annotation: one highlight
-- group per kind, coloured by mixing that kind's icon colour with Comment so
-- each hue stays recognisable while sitting back from the symbol name. Mixing
-- toward Comment rather than toward the background is deliberate — catppuccin
-- runs with transparent_background, so Normal has no bg to blend with.
local KIND_MIX = 0.5

---@type table<string, true>
local made = {}

---Mix two 0xRRGGBB colours, keeping `alpha` of the first.
---@param a integer
---@param b integer
---@param alpha number
---@return integer
local function mix(a, b, alpha)
  local out = {}
  for i, shift in ipairs({ 65536, 256, 1 }) do
    local ca, cb = math.floor(a / shift) % 256, math.floor(b / shift) % 256
    out[i] = math.floor(ca * alpha + cb * (1 - alpha) + 0.5)
  end
  return out[1] * 65536 + out[2] * 256 + out[3]
end

---Highlight group for one kind's label, created on first use.
---@param kind string
---@param icon_hl string Highlight group mini.icons uses for this kind's icon.
---@return string
function M.kind_hl(kind, icon_hl)
  local name = "MiniPickKind" .. kind:gsub("%W", "")
  if made[name] then
    return name
  end
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local icon = vim.api.nvim_get_hl(0, { name = icon_hl, link = false })
  local fg = comment.fg
  if icon.fg and comment.fg then
    fg = mix(icon.fg, comment.fg, KIND_MIX)
  end
  vim.api.nvim_set_hl(0, name, { fg = fg, italic = true })
  made[name] = true
  return name
end

---Highlight group for the breadcrumb trail, created on first use.
---
---`Comment` with italics added — a `link` would drop the italic, and the trail
---is context rather than a symbol, so it takes no per-kind hue.
---@return string
function M.crumb_hl()
  local name = "MiniPickSymbolCrumb"
  if not made[name] then
    local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
    vim.api.nvim_set_hl(0, name, { fg = comment.fg, italic = true })
    made[name] = true
  end
  return name
end

---Reserve (or release) a display row above the window's first line.
---
---Neovim clips a `virt_lines_above` mark on the topline: the line is part of
---the layout (`nvim_win_text_height` counts it) but there is nowhere to draw
---it, so `topfill` has to reserve the row. Without this the breadcrumb above
---the *first* result is silently missing while every other one renders.
---
---Deferred because mini.pick sets the cursor after `source.show` returns,
---which resets the view — so this has to land after each of its renders.
---@param win integer
---@param needed boolean Whether the first line carries a trail.
function M.reserve_trail_row(win, needed)
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    local want = needed and 1 or 0
    local changed = vim.api.nvim_win_call(win, function()
      if vim.fn.winsaveview().topfill == want then
        return false
      end
      vim.fn.winrestview({ topfill = want })
      return true
    end)
    -- `winrestview` moves the view without repainting, and mini.pick drew this
    -- frame before the callback ran — so without this the reserved row stays
    -- blank until the next keystroke happens to redraw.
    if changed then
      vim.cmd("redraw")
    end
  end)
end

-- Label colours are derived from the active theme's icon and Comment groups,
-- so drop the cache on a colorscheme change and let the next render rebuild
-- them against the new palette.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("MiniPickers.Highlights", { clear = true }),
  desc = "Rebuild symbol picker label colours against the new palette",
  callback = function()
    made = {}
  end,
})

return M
