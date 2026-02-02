-- github.com/nvim-mini/mini.statusline
-- Status line

-- Custom highlights for statusline sections
local function set_statusline_highlights()
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = "#1a1a2e" })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })
set_statusline_highlights()

-- Custom location section with L and C prefixes
local function section_location(args)
  local MiniStatusline = require("mini.statusline")
  if MiniStatusline.is_truncated(args.trunc_width) then
    return "L %l │ C %2v"
  end
  return "L %l|%L │ C %2v|%-2{virtcol('$') - 1}"
end

---@module "lazy"
---@type LazySpec
return {
  "nvim-mini/mini.statusline",
  version = "*",
  opts = {
    content = {
      active = function()
        local MiniStatusline = require("mini.statusline")

        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
        local git = MiniStatusline.section_git({ trunc_width = 40 })
        local diff = MiniStatusline.section_diff({ trunc_width = 75 })
        local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
        local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
        local filename = MiniStatusline.section_filename({ trunc_width = 140 })
        local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
        local location = section_location({ trunc_width = 75 })
        local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

        local statusline = MiniStatusline.combine_groups({
          { hl = mode_hl, strings = { mode } },
          { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
          "%<",
          { hl = "MiniStatuslineFilename", strings = { filename } },
          "%=",
          { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
          { hl = mode_hl, strings = { search, location } },
        })
        -- Remove leading/trailing spaces to move content closer to edges
        return statusline:gsub("^(%%#%S+#) +", "%1"):gsub(" +$", "")
      end,
    },
  },
}
