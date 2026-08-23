local M = {}

---Closes floating windows - runs before a session is written, so floats are not
---serialized into it and the layout restores properly
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

-- Where a jump target should sit vertically in the window: 30% down from the
-- top, so the landing line has context above it and room to read below.
local REVEAL_RATIO = 0.3

---Scroll the current window so the cursor line sits ~30% down from the top.
---Scrolls the view only — the cursor stays on the same buffer line. `zt` first
---so the correction is always upward (`<C-y>` can never drag the cursor along),
---then `winline()` measures the real screen row, which keeps the result honest
---under folds, `scrolloff`, and near the ends of the buffer.
function M.reveal_cursor()
  vim.cmd("normal! zt")
  local delta = math.floor(vim.api.nvim_win_get_height(0) * REVEAL_RATIO) - vim.fn.winline()
  if delta > 0 then
    vim.cmd("normal! " .. delta .. "\25") -- <C-y>
  end
end

---Run an LSP jump, then reveal wherever it lands.
---LSP jumps are async, so the reposition can't follow inline; it is armed as a
---one-shot `CursorMoved` instead. Jumps that land in the quickfix list (several
---results) leave it to be consumed harmlessly by the next cursor move.
---@param jump fun() The jump to perform, e.g. `vim.lsp.buf.definition`.
function M.jump_then_reveal(jump)
  vim.api.nvim_create_autocmd("CursorMoved", {
    once = true,
    callback = function()
      if vim.bo.buftype == "" then
        M.reveal_cursor()
      end
    end,
  })
  jump()
end

return M
