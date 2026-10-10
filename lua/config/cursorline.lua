-- Neovim paints a wrapped line's 'breakindent' with the decoration covering the
-- character before the wrap, but never with CursorLine (only 'showbreak' gets
-- that). A lowest-priority CursorLine mark over the cursor line fills the gap,
-- and 'winhighlight' still remaps it, so modes.nvim's colours reach it too.
-- ponytail: a row ending under an underline (a diagnostic) keeps its gap, since
-- Neovim leaves underlines out of it. Drop once 'breakindent' takes CursorLine.

local ns = vim.api.nvim_create_namespace("cursorline_breakindent")

---@param win integer
---@return boolean
local function paints_line(win)
  local opts = vim.split(vim.wo[win].cursorlineopt, ",")
  return vim.wo[win].cursorline and (vim.list_contains(opts, "line") or vim.list_contains(opts, "both"))
end

-- Ephemeral rather than a mark moved on CursorMoved: marks belong to the buffer,
-- and each window showing it has its own cursor line.
vim.api.nvim_set_decoration_provider(ns, {
  on_win = function(_, win, buf)
    if not paints_line(win) then
      return false
    end
    local row = vim.api.nvim_win_get_cursor(win)[1] - 1
    vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
      end_row = row + 1,
      hl_group = "CursorLine",
      priority = 1,
      ephemeral = true,
      strict = false,
    })
  end,
})
