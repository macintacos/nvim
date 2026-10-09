---Builds 'statusline' out of mode, git, diagnostic, filename, and location sections.
---@see https://github.com/nvim-mini/mini.statusline/blob/main/doc/mini-statusline.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.statusline", version = "stable" } })

local pack_updates = require("plugins.pack-updates")

-- Override default section backgrounds so the line sits just off the terminal
-- background and only the mode sections carry color. Light steps one shade past
-- the filename's mantle, but leaves the update count on mantle: green on crust
-- reads at under 4:1.
local function set_statusline_highlights()
  if vim.o.background == "light" then
    local p = require("catppuccin.palettes").get_palette()
    vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = p.crust })
    vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = p.crust })
    vim.api.nvim_set_hl(0, "MiniStatuslinePackUpdates", { fg = p.green, bg = p.mantle })
    -- catppuccin letters Normal in mantle, which on Latte is darker than base
    -- and so loses contrast on blue rather than gaining it.
    vim.api.nvim_set_hl(0, "MiniStatuslineModeNormal", { fg = p.base, bg = p.blue, bold = true })
    return
  end
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslinePackUpdates", { fg = "#a6e3a1", bg = "#1a1a2e" })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })
set_statusline_highlights()

-- Custom statusline section: shows a braille spinner while checking
-- for plugin updates, then icon + count when updates are available.
---@param args { trunc_width: integer }
---@return string
local function section_pack_updates(args)
  if MiniStatusline.is_truncated(args.trunc_width) then
    return ""
  end
  local frame = pack_updates.spinner_frame()
  if frame then
    return frame
  end
  local n = pack_updates.update_count()
  if n > 0 then
    return " " .. n
  end
  return ""
end

require("mini.statusline").setup({
  content = {
    active = function()
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local git = MiniStatusline.section_git({ trunc_width = 40 })
      local diff = MiniStatusline.section_diff({ trunc_width = 75 })
      local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
      local filename = MiniStatusline.section_filename({ trunc_width = 140 })
      local location = MiniStatusline.section_location({ trunc_width = 75 })
      local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
      local updates = section_pack_updates({ trunc_width = 75 })

      return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=",
        { hl = "MiniStatuslinePackUpdates", strings = { updates } },
        { hl = mode_hl, strings = { search, location } },
      })
    end,
  },
})
