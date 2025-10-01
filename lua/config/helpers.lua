local M = {}

---Convenience function that wraps the given string with `<Cmd>` and `<CR>`
---@param command string The command to wrap.
function M.Cmd(command)
  return "<Cmd>" .. command .. "<CR>"
end

---Closes floating windows - especially useful in auto-session, to make sure that things are restored properly
function M.close_all_floating_wins()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, false)
    end
  end
end

return M
