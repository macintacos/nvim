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

local OPPOSITE = { h = "l", j = "k", k = "j", l = "h" }

---Move a border of the current window one cell toward `dir`: the border on that
---side when a window lies there, otherwise the opposite one, so a window at the
---screen's edge still answers every direction.
---@param dir "h"|"j"|"k"|"l"
function M.resize(dir)
  local current = vim.fn.winnr()
  local side = vim.fn.winnr(dir) ~= current and dir or OPPOSITE[dir]
  local neighbor = vim.fn.winnr(side)
  -- Also keeps a full-height window's status line still, which would resize the cmdline.
  if neighbor == current then
    return
  end
  -- A window owns only its right separator and bottom status line.
  local owner = (side == "h" or side == "k") and neighbor or current
  local offset = (dir == "h" or dir == "k") and -1 or 1
  if dir == "h" or dir == "l" then
    vim.fn.win_move_separator(owner, offset)
  else
    vim.fn.win_move_statusline(owner, offset)
  end
end

-- Where a jump target should sit vertically in the window: 30% down from the
-- top, so the landing line has context above it and room to read below.
local REVEAL_RATIO = 0.3

---The top line that leaves at most `rows` screen lines above `lnum` in the current
---window, a closed fold counting as one.
---@param lnum integer
---@param rows integer
---@return integer
local function top_line(lnum, rows)
  local top = lnum
  while top > 1 do
    local above = vim.fn.foldclosed(top - 1)
    above = above == -1 and top - 1 or above
    if vim.api.nvim_win_text_height(0, { start_row = above - 1, end_row = lnum - 2 }).all > rows then
      break
    end
    top = above
  end
  return top
end

---Scroll the current window so the cursor line sits ~30% down from the top.
---Scrolls the view only — the cursor stays on the same buffer line, and
---'scrolloff' still wins over the 30%.
---
---Sets the top line instead of running `zt`/`<C-y>`: keys run here reach every
---`vim.on_key` listener as if typed in this window, and a preview runs this in a
---window the user is not in.
function M.reveal_cursor()
  local rows = math.floor(vim.api.nvim_win_get_height(0) * REVEAL_RATIO) - 1
  vim.fn.winrestview({ topline = top_line(vim.fn.line("."), rows) })
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
