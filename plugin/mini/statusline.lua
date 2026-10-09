---Builds 'statusline' out of mode, git, diagnostic, filename, and location sections.
---@see https://github.com/nvim-mini/mini.statusline/blob/main/doc/mini-statusline.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.statusline", version = "stable" } })

local pack_updates = require("plugins.pack-updates")

-- Override default section backgrounds so the line sits just off the terminal
-- background and only the mode sections carry color.
local function set_statusline_highlights()
  local p, spec = require("helpers.palette").active()
  -- The shade the fox's spec uses for its louder syntax roles, which clears 7:1
  -- under bg1 in both foxes.
  local shade = vim.o.background == "light" and "dim" or "bright"
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = spec.bg0 })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = spec.bg0 })
  vim.api.nvim_set_hl(0, "MiniStatuslinePackUpdates", { fg = p.green.base, bg = spec.bg0 })
  local modes = {
    Normal = p.blue,
    Insert = p.green,
    Visual = p.magenta,
    Replace = p.red,
    Command = p.orange,
    Other = p.cyan,
  }
  for mode, color in pairs(modes) do
    vim.api.nvim_set_hl(0, "MiniStatuslineMode" .. mode, { fg = spec.bg1, bg = color[shade], bold = true })
  end
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })

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
