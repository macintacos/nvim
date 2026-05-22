local M = {}

---@class gotoline.Config

---`GotolineHelp` is Comment's foreground without italic. We copy the fg at
---setup time (and on each `ColorScheme` change) so the helper text picks up
---whatever dim color the active theme uses for comments, but never inherits
---the italic styling most themes apply.
local function refresh_help_hl()
  local c = vim.api.nvim_get_hl(0, { name = "Comment", link = false }) or {}
  vim.api.nvim_set_hl(0, "GotolineHelp", { default = true, fg = c.fg, italic = false })
end

---@param _opts gotoline.Config|nil
function M.setup(_opts)
  vim.api.nvim_set_hl(0, "GotolineTargetLine", { default = true, link = "Visual" })
  vim.api.nvim_set_hl(0, "GotolineSelected", { default = true, link = "CursorLine" })
  vim.api.nvim_set_hl(0, "GotolineMatch", { default = true, link = "Special" })
  refresh_help_hl()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("Gotoline.Highlights", { clear = true }),
    desc = "Refresh GotolineHelp after colorscheme change",
    callback = refresh_help_hl,
  })
  vim.api.nvim_create_user_command("GoToLine", function()
    M.open()
  end, { desc = "Open the GoToLine modal" })
end

function M.open()
  require("plugins.gotoline.ui").open()
end

return M
