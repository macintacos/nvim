-- github.com/nvim-mini/mini.statusline
-- Status line

-- Custom highlights for statusline sections
local function set_statusline_highlights()
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = "#1a1a2e" })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })
set_statusline_highlights()

---@module "lazy"
---@type LazySpec
return {
  "nvim-mini/mini.statusline",
  version = "*",
  opts = {},
}
