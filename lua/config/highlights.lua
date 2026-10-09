-- Custom highlight groups.

-- Flash colors for yank/paste feedback. Copy flashes green (FlashYank, used by
-- the TextYankPost autocmd in lua/config/autocmds.lua) and paste flashes blue
-- (FlashPaste, used by the paste wrapper in plugin/smart-paste.lua), so it's
-- clear both where the region is and which operation just happened.
local function set_flash_hl()
  local p, spec = require("helpers.palette").active()
  vim.api.nvim_set_hl(0, "FlashYank", { bg = p.green.base, fg = spec.bg1 })
  vim.api.nvim_set_hl(0, "FlashPaste", { bg = p.blue.base, fg = spec.bg1 })
end

-- Query matches in mini.pick: solid blocks in the list and the preview.
--
-- The list marks matches at extmark priority 200 and the current row at 201,
-- so the row's colours win over the match's on that row. `reverse` is a flag,
-- and flags survive the override: a match draws as a blue block on other rows
-- and as a block of the current row's foreground on the current one. Blue, like
-- the match characters of every other picker.
local function set_picker_match_hl()
  local p, spec = require("helpers.palette").active()
  vim.api.nvim_set_hl(0, "MiniPickMatchRanges", { fg = p.blue.base, bg = spec.bg1, reverse = true, bold = true })
  vim.api.nvim_set_hl(0, "MiniPickPreviewRegion", { fg = spec.bg1, bg = p.blue.base, bold = true })
end

-- Ctrl-hover over a link or path (helpers.links). sel0, the selection colour:
-- syntax colours stay legible on it, where bg4 drops accents below 4.5. The underline matches herdr's own ctrl-hover one,
-- which blinks as Neovim redraws; this keeps it steady underneath.
local function set_link_hover_hl()
  local p, spec = require("helpers.palette").active()
  vim.api.nvim_set_hl(0, "LinkHover", { bg = spec.sel0, underline = true })
  vim.api.nvim_set_hl(0, "LinkHoverIcon", { fg = p.blue.base, bg = spec.sel0 })
end

-- changeset.nvim's unified diff: an added or deleted line's background, and the
-- stronger one behind the characters it changed. Overrides changeset's defaults,
-- which it derives from the theme.
local function set_changeset_diff_hl()
  local _, spec = require("helpers.palette").active()
  vim.api.nvim_set_hl(0, "ChangesetDiffAdd", { bg = spec.diff.add })
  vim.api.nvim_set_hl(0, "ChangesetDiffAddText", { bg = spec.diff.text })
  vim.api.nvim_set_hl(0, "ChangesetDiffDelete", { bg = spec.diff.delete })
  vim.api.nvim_set_hl(0, "ChangesetDiffDeleteText", { bg = spec.diff.text })
end

-- render-markdown's heading bands, one tint of the heading colour for every level.
-- Its defaults are the diff backgrounds, which make an H4 read as a deleted line.
local function set_heading_band_hl()
  local _, spec = require("helpers.palette").active()
  local band = require("helpers.palette").blend(spec.bg1, spec.syntax.func, 0.15)
  for level = 1, 6 do
    vim.api.nvim_set_hl(0, "RenderMarkdownH" .. level .. "Bg", { bg = band })
  end
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups.
-- Fires when the fox loads at startup (plugin/nightfox.lua) and on every
-- 'background' flip, which reloads it.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "fox",
  callback = function()
    set_flash_hl()
    set_picker_match_hl()
    set_link_hover_hl()
    set_changeset_diff_hl()
    set_heading_band_hl()
  end,
})
