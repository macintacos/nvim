-- Custom highlight groups.

-- Flash colors for yank/paste feedback. Copy flashes green (FlashYank, used by
-- the TextYankPost autocmd in lua/config/autocmds.lua) and paste flashes blue
-- (FlashPaste, used by the paste wrapper in plugin/smart-paste.lua), so it's
-- clear both where the region is and which operation just happened. Colors are
-- pulled from the active catppuccin palette so they track the theme.
local function set_flash_hl()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if not ok then
    return
  end
  local p = palettes.get_palette()
  vim.api.nvim_set_hl(0, "FlashYank", { bg = p.green, fg = p.base })
  vim.api.nvim_set_hl(0, "FlashPaste", { bg = p.blue, fg = p.base })
end

-- Badge drawn in place of a closed fold by lua/config/folds.lua. The caps are
-- rounded half-blocks tinted with the badge's own background so they read as
-- its edges; the body carries the fold's blue on a raised surface, and only the
-- diagnostic counts break out of that palette.
local function set_fold_hl()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if not ok then
    return
  end
  local p = palettes.get_palette()
  vim.api.nvim_set_hl(0, "FoldChipEdge", { fg = p.surface1, bg = "NONE" })
  vim.api.nvim_set_hl(0, "FoldChip", { fg = p.blue, bg = p.surface1 })
  vim.api.nvim_set_hl(0, "FoldChipError", { fg = p.red, bg = p.surface1 })
  vim.api.nvim_set_hl(0, "FoldChipWarn", { fg = p.yellow, bg = p.surface1 })
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups.
-- Fires when catppuccin loads at startup (plugin/catppuccin.lua) and on any
-- later colorscheme change. The immediate call covers manual :source of this
-- file after catppuccin is already loaded.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*",
  callback = function()
    set_flash_hl()
    set_fold_hl()
  end,
})

set_flash_hl()
set_fold_hl()
