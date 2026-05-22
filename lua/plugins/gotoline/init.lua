local M = {}

---@class gotoline.Config

---@param _opts gotoline.Config|nil
function M.setup(_opts)
  vim.api.nvim_set_hl(0, "GotolineTargetLine", { default = true, link = "Visual" })
  vim.api.nvim_set_hl(0, "GotolineSelected", { default = true, link = "CursorLine" })
  vim.api.nvim_set_hl(0, "GotolineMatch", { default = true, link = "Special" })
end

function M.open()
  require("plugins.gotoline.ui").open()
end

return M
