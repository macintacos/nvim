local M = {}

---@type vim.ui.open.Opts
local BLOOM = { cmd = { "open", "-a", "Bloom" } }

---The http(s) URL inside `word`, if it holds one.
---@param word string
---@return string?
function M.url(word)
  local url = word:match("(https?://[%w_.~!*'();:@&=+$,/?#%%[%]%-]+)")
  if not url then
    return nil
  end
  url = url:gsub("[.,;:!?'*]+$", "")
  -- A `)` with no `(` in the URL closes the markdown link or prose around it.
  if not url:find("(", 1, true) then
    url = url:gsub("%)+$", "")
  end
  return url
end

---What sits under the cursor that `vim.ui.open` can open: a URL, or a file or
---directory found from the buffer's directory or the cwd, routed to Bloom.
---@return string? target
---@return vim.ui.open.Opts? opts
---@return string? text The buffer text naming the target.
function M.under_cursor()
  local url = M.url(vim.fn.expand("<cWORD>") --[[@as string]])
  if url then
    return url, nil, url
  end
  local name = vim.fn.expand("<cfile>") --[[@as string]]
  if name == "" then
    return nil
  end
  local found = vim.fn.findfile(name, ".,,") --[[@as string]]
  if found == "" then
    found = vim.fn.finddir(name, ".,,") --[[@as string]]
  end
  if found == "" then
    return nil
  end
  local path = vim.fn.fnamemodify(found, ":p") --[[@as string]]
  return path, BLOOM, name
end

---0-based, end-exclusive byte span of the occurrence of `text` in `line` that
---covers `col`.
---@param line string
---@param col integer 0-based byte column
---@param text string
---@return integer? start
---@return integer? finish
function M._span(line, col, text)
  local init = 1
  while true do
    local s, e = line:find(text, init, true)
    if not s then
      return nil
    end
    if col >= s - 1 and col < e then
      return s - 1, e
    end
    init = s + 1
  end
end

---@class helpers.links.Hit
---@field target string URL or absolute path
---@field kind "url"|"path"
---@field opts? vim.ui.open.Opts
---@field buf integer
---@field row integer 0-based
---@field col integer 0-based start of the text naming the target
---@field end_col integer End-exclusive

---`under_cursor` evaluated at the mouse position, leaving the cursor where it was.
---@return helpers.links.Hit?
function M.at_mouse()
  local pos = vim.fn.getmousepos()
  if pos.line == 0 then
    return nil
  end
  local row, col = pos.line - 1, pos.column - 1
  ---@type string?, vim.ui.open.Opts?, string?
  local target, opts, text
  vim.api.nvim_win_call(pos.winid, function()
    local saved = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { pos.line, col })
    target, opts, text = M.under_cursor()
    vim.api.nvim_win_set_cursor(0, saved)
  end)
  if not target then
    return nil
  end
  local buf = vim.api.nvim_win_get_buf(pos.winid)
  -- The cursor was just placed on this row, so the line exists.
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] --[[@as string]]
  -- <cWORD> and <cfile> reach forward to the next word from blank space.
  local s, e = M._span(line, col, text --[[@as string]])
  if not s or not e then
    return nil
  end
  local kind = opts and "path" or "url"
  return { target = target, kind = kind, opts = opts, buf = buf, row = row, col = s, end_col = e }
end

local hover_ns = vim.api.nvim_create_namespace("helpers.links.hover")

---@type table<"url"|"path", string>
local ICONS = { url = "󰖟 ", path = "󰏌 " }

---@type integer? Buffer holding the hover highlight.
local hovered

---Clear the hover highlight.
function M.unhover()
  if hovered and vim.api.nvim_buf_is_valid(hovered) then
    vim.api.nvim_buf_clear_namespace(hovered, hover_ns, 0, -1)
  end
  hovered = nil
end

---Highlight what a ctrl-click at the mouse would open (`LinkHover`), prefixed
---with an icon for its kind (`LinkHoverIcon`).
function M.hover()
  -- Before unhover: the mouse position is read against the icon still on screen.
  local hit = M.at_mouse()
  M.unhover()
  if hit then
    vim.api.nvim_buf_set_extmark(hit.buf, hover_ns, hit.row, hit.col, {
      end_col = hit.end_col,
      hl_group = "LinkHover",
      virt_text = { { ICONS[hit.kind], "LinkHoverIcon" } },
      virt_text_pos = "inline",
    })
    hovered = hit.buf
  end
end

return M
