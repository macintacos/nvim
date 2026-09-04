-- Render a closed fold the way mkdnflow draws one in markdown: the fold's first
-- line on the left, a summary of what it hides on the right, and a braille run
-- stretched between them so the row reads as one filled bar.
--
-- An empty 'foldtext' draws the fold's own source, which reads like an ordinary
-- line. Returning a plain string replaces the whole line and paints it with
-- Folded end to end; virtual-text chunks would let each part carry its own
-- color, but only a single string spans the row as one bar.

local M = {}

-- Braille fill, matching mkdnflow's 'foldtext' defaults so a folded function and
-- a folded heading read as the same object.
local EDGE_LEFT, EDGE_RIGHT = "⢾⣿⣿", "⣿⣿⡷"
local INSIDE_LEFT, INSIDE_RIGHT = " ⣹", "⣏ "
local MIDDLE = "⣿"
local ITEM_SEP = " · "
local SECTION_SEP = " ⣹⣿⣏ "
local ELLIPSIS = "…"

-- The chevron 'fillchars' foldclose puts in the gutter (U+F460), repeated on the
-- line so both marks for one fold match.
local COLLAPSED = ""

---Diagnostic severities worth surfacing, most severe first.
---@type { level: integer, icon: string }[]
local SEVERITIES = {
  { level = vim.diagnostic.severity.ERROR, icon = "" },
  { level = vim.diagnostic.severity.WARN, icon = "" },
}

---Counts of the diagnostics a fold hides.
---@param first integer 1-indexed first folded line
---@param last integer 1-indexed last folded line
---@return string[] Empty when the fold hides nothing of note
local function diagnostic_counts(first, last)
  local counts = {}
  for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
    if diagnostic.lnum >= first - 1 and diagnostic.lnum <= last - 1 then
      counts[diagnostic.severity] = (counts[diagnostic.severity] or 0) + 1
    end
  end

  local formatted = {}
  for _, severity in ipairs(SEVERITIES) do
    local count = counts[severity.level]
    if count then
      formatted[#formatted + 1] = ("%s %d"):format(severity.icon, count)
    end
  end
  return formatted
end

---What the fold hides, as the bar's right-hand text: diagnostic counts in one
---section, the fold's size in the next.
---@param hidden integer Lines the fold conceals, the first one excepted
---@param diagnostics string[] Formatted diagnostic counts
---@param total integer Lines in the buffer
---@return string
local function summary(hidden, diagnostics, total)
  local size = table.concat({
    ("%d %s"):format(hidden, hidden == 1 and "line" or "lines"),
    ("%.1f%%"):format(hidden / total * 100),
  }, ITEM_SEP)

  if #diagnostics == 0 then
    return size
  end
  return table.concat(diagnostics, ITEM_SEP) .. SECTION_SEP .. size
end

---`text` cut down to at most `width` columns, ending in an ellipsis when
---something had to go. Trimming by character count overshoots on wide glyphs,
---so the guess is walked back until it measures.
---@param text string
---@param width integer Columns the text may occupy
---@return string
local function fit(text, width)
  if width <= 0 then
    return ""
  end
  if vim.api.nvim_strwidth(text) <= width then
    return text
  end
  local kept = vim.fn.strcharpart(text, 0, width - 1)
  while vim.api.nvim_strwidth(kept) >= width do
    kept = vim.fn.strcharpart(kept, 0, vim.fn.strchars(kept) - 1)
  end
  return kept .. ELLIPSIS
end

---One bar spanning `width` columns, its two labels pushed to the edges. The
---summary is what a reader can't reconstruct from the buffer, so a narrow window
---eats into the title rather than pushing the summary off the right edge.
---@param title string Left-hand label
---@param info string Right-hand summary
---@param width integer Columns available for text
---@return string
local function bar(title, info, width)
  local right = INSIDE_RIGHT .. info .. INSIDE_LEFT .. EDGE_RIGHT
  local chrome = EDGE_LEFT .. INSIDE_RIGHT .. INSIDE_LEFT .. right
  local left = EDGE_LEFT .. INSIDE_RIGHT .. fit(title, width - vim.api.nvim_strwidth(chrome)) .. INSIDE_LEFT
  local fill = width - vim.api.nvim_strwidth(left .. right)
  return left .. MIDDLE:rep(math.max(fill, 0)) .. right
end

---Columns the window gives to buffer text, once 'foldcolumn', 'signcolumn' and
---the number column have taken theirs.
---@return integer
local function text_width()
  local win = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  return win.width - win.textoff
end

---'foldtext' expression: a bar standing in for the closed fold.
---@return string
function M.foldtext()
  local first, last = vim.v.foldstart, vim.v.foldend
  -- Tabs expanded so the bar starts at the same column as the block it replaces.
  local line = vim.fn.getline(first):gsub("\t", (" "):rep(vim.bo.tabstop))
  local indent = line:match("^%s*")
  local hidden = last - first

  return indent
    .. bar(
      ("%s %s"):format(COLLAPSED, vim.trim(line)),
      summary(hidden, diagnostic_counts(first, last), vim.api.nvim_buf_line_count(0)),
      text_width() - #indent
    )
end

M._bar = bar
M._summary = summary

return M
