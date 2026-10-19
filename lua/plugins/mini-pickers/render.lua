---Shared render primitives for the pickers.
---
---Both symbol pickers annotate rows with the same vocabulary — a kind label in the
---symbol's own hue, and dim context text — so the namespace they draw into and
---the highlight groups they draw with live here.

local M = {}

M.ns = vim.api.nvim_create_namespace("mini_pick_lsp_symbols")

-- Subdued italic labels for the right-aligned kind annotation: one highlight
-- group per kind, coloured by mixing that kind's icon colour with Comment so
-- each hue stays recognisable while sitting back from the symbol name. Mixing
-- toward Comment rather than toward the background keeps the label as legible
-- as Comment.
local KIND_MIX = 0.5

---@type table<string, boolean>
local made = {}

---Mix two 0xRRGGBB colours, keeping `alpha` of the first.
---@param a integer
---@param b integer
---@param alpha number
---@return integer
local function mix(a, b, alpha)
  local out = {}
  for i, shift in ipairs({ 65536, 256, 1 }) do
    local ca, cb = math.floor(a / shift) % 256, math.floor(b / shift) % 256
    out[i] = math.floor(ca * alpha + cb * (1 - alpha) + 0.5)
  end
  return out[1] * 65536 + out[2] * 256 + out[3]
end

---Highlight group for one kind's label, created on first use.
---@param kind string
---@param icon_hl string Highlight group mini.icons uses for this kind's icon.
---@return string
function M.kind_hl(kind, icon_hl)
  local name = "MiniPickKind" .. kind:gsub("%W", "")
  if made[name] then
    return name
  end
  local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
  local icon = vim.api.nvim_get_hl(0, { name = icon_hl, link = false })
  local fg = comment.fg
  if icon.fg and comment.fg then
    fg = mix(icon.fg, comment.fg, KIND_MIX)
  end
  vim.api.nvim_set_hl(0, name, { fg = fg, italic = true })
  made[name] = true
  return name
end

---Highlight group for the breadcrumb trail, created on first use.
---
---`Comment` with italics added — a `link` would drop the italic, and the trail
---is context rather than a symbol, so it takes no per-kind hue.
---@return string
function M.crumb_hl()
  local name = "MiniPickSymbolCrumb"
  if not made[name] then
    local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
    vim.api.nvim_set_hl(0, name, { fg = comment.fg, italic = true })
    made[name] = true
  end
  return name
end

---Reserve (or release) a display row above the window's first line.
---
---Neovim clips a `virt_lines_above` mark on the topline: the line is part of
---the layout (`nvim_win_text_height` counts it) but there is nowhere to draw
---it, so `topfill` has to reserve the row. Without this the breadcrumb above
---the *first* result is silently missing while every other one renders.
---
---Call it after `MiniPick.default_show`, on every render: rewriting the lines
---drops `topfill`, and mini.pick draws the frame as soon as `source.show`
---returns. Deferring it paints the list a row off first, a visible jump.
---@param win integer
---@param needed boolean Whether the first line carries a trail.
function M.reserve_trail_row(win, needed)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local want = needed and 1 or 0
  vim.api.nvim_win_call(win, function()
    if vim.fn.winsaveview().topfill ~= want then
      vim.fn.winrestview({ topfill = want })
    end
  end)
end

---Byte range of `path` to hide behind a one-cell ellipsis so it fits `width`
---cells. The range is centered in the directories, so the filename stays whole;
---a filename too long for that loses its start instead.
---@param path string
---@param width integer
---@return [integer, integer]? range `{ from, to }`, nil when the path fits.
local function middle_cut(path, width)
  local hide = vim.api.nvim_strwidth(path) - width + 1
  if hide <= 1 then
    return nil
  end
  local dirs = vim.api.nvim_strwidth(path:match("^(.*)/") or "")
  local lead = math.max(math.floor((dirs - hide) / 2), 0)

  local kept, hidden, from, byte = 0, 0, 1, 1
  for char in path:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    local cells = vim.api.nvim_strwidth(char)
    if hidden == 0 and kept + cells <= lead then
      kept, from = kept + cells, byte + #char
    else
      hidden = hidden + cells
      if hidden >= hide then
        return { from, byte + #char - 1 }
      end
    end
    byte = byte + #char
  end
  return { from, #path }
end

---`source.show` for pickers whose items are paths: icons in front, and the
---middle of a path too long for the list concealed so its filename shows.
---
---Concealing rather than shortening the text keeps mini.pick's match
---highlights on the characters they belong to.
---@param buf_id integer
---@param items (string|{ text: string })[]
---@param query string[]
function M.show_paths(buf_id, items, query)
  MiniPick.default_show(buf_id, items, query, { show_icons = true })
  vim.api.nvim_buf_clear_namespace(buf_id, M.ns, 0, -1)

  local win = vim.fn.bufwinid(buf_id)
  if win == -1 then
    return
  end
  vim.wo[win].conceallevel = 2
  -- The picker's cursor sits on the current item, which would otherwise show
  -- its path uncut.
  vim.wo[win].concealcursor = "nvic"
  local width = vim.api.nvim_win_get_width(win)

  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  for i, item in ipairs(items) do
    local path = (type(item) == "table" and item.text or item) --[[@as string]]
    local line = assert(lines[i], "default_show writes a line per item")
    local offset = #line - #path -- the icon in front of the path
    local range = middle_cut(path, width - vim.api.nvim_strwidth(line:sub(1, offset)))
    if range then
      vim.api.nvim_buf_set_extmark(buf_id, M.ns, i - 1, offset + range[1] - 1, {
        end_col = offset + range[2],
        conceal = "…",
      })
    end
  end
end

-- Label colours are derived from the active theme's icon and Comment groups,
-- so drop the cache on a colorscheme change and let the next render rebuild
-- them against the new palette.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("MiniPickers.Highlights", { clear = true }),
  desc = "Rebuild symbol picker label colours against the new palette",
  callback = function()
    made = {}
  end,
})

return M
