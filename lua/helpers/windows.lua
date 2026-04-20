local M = {}

---Closes floating windows - especially useful in auto-session, to make sure that things are restored properly
function M.close_all_floating_wins()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, false)
    end
  end
end

---Scroll the LSP hover popup, if one is open for the current buffer.
---@param direction "down"|"up"
---@return boolean scrolled true if a hover popup was found and scrolled
function M.scroll_hover(direction)
  local ok, winid = pcall(vim.api.nvim_buf_get_var, 0, "lsp_floating_preview")
  if not ok or not winid or not vim.api.nvim_win_is_valid(winid) then
    return false
  end
  local key = vim.api.nvim_replace_termcodes(direction == "down" and "<C-d>" or "<C-u>", true, false, true)
  vim.api.nvim_win_call(winid, function()
    vim.cmd("normal! " .. key)
  end)
  return true
end

return M
