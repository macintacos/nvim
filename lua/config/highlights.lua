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

-- Query matches in mini.pick: solid blocks in the list and the preview.
--
-- The list marks matches at extmark priority 200 and the current row at 201,
-- so the row's colours win over the match's on that row. `reverse` is a flag,
-- and flags survive the override: a match draws as a teal block on other rows
-- and as a block of the current row's foreground on the current one.
local function set_picker_match_hl()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if not ok then
    return
  end
  local p = palettes.get_palette()
  vim.api.nvim_set_hl(0, "MiniPickMatchRanges", { fg = p.teal, bg = p.base, reverse = true, bold = true })
  vim.api.nvim_set_hl(0, "MiniPickPreviewRegion", { fg = p.base, bg = p.teal, bold = true })
end

-- Ctrl-hover over a link or path (helpers.links). surface1, as surface0 barely
-- differs from CursorLine. The underline matches herdr's own ctrl-hover one,
-- which blinks as Neovim redraws; this keeps it steady underneath.
local function set_link_hover_hl()
  local ok, palettes = pcall(require, "catppuccin.palettes")
  if not ok then
    return
  end
  local p = palettes.get_palette()
  vim.api.nvim_set_hl(0, "LinkHover", { bg = p.surface1, underline = true })
  vim.api.nvim_set_hl(0, "LinkHoverIcon", { fg = p.blue, bg = p.surface1 })
end

-- changeset.nvim's unified diff: an added or deleted line's background, and the
-- stronger one behind the characters it changed. Overrides changeset's defaults,
-- which it derives from the theme.
local function set_changeset_diff_hl()
  vim.api.nvim_set_hl(0, "ChangesetDiffAdd", { bg = "#192a1f" })
  vim.api.nvim_set_hl(0, "ChangesetDiffAddText", { bg = "#315b32" })
  vim.api.nvim_set_hl(0, "ChangesetDiffDelete", { bg = "#29191d" })
  vim.api.nvim_set_hl(0, "ChangesetDiffDeleteText", { bg = "#7b3632" })
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups.
-- Fires when catppuccin loads at startup (plugin/catppuccin.lua) and on any
-- later colorscheme change. The immediate call covers manual :source of this
-- file after catppuccin is already loaded.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "catppuccin*",
  callback = function()
    set_flash_hl()
    set_picker_match_hl()
    set_link_hover_hl()
    set_changeset_diff_hl()
  end,
})

set_flash_hl()
set_picker_match_hl()
set_link_hover_hl()
set_changeset_diff_hl()
