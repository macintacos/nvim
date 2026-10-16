-- Which symmetric delimiters in a markdown buffer have no partner. Delimiters
-- pair up left to right within a paragraph, so an odd count leaves the last one
-- unmatched. Both the unmatched-delimiter highlight and the markdown pairing
-- rules count through here, so a highlighted delimiter is what stops the next
-- one from auto-closing.

local M = {}

---@alias blink_pairs.Pos [integer, integer] 0-based row and byte column

-- `'` and `$` stay out: apostrophes and prices would always read as unmatched.
local CHARS = '`"*_~'
local DELIMITER = "[" .. CHARS .. "]"

-- Literal text: code, URLs, HTML, and escapes. Code blocks and frontmatter are
-- blocks, not paragraphs, so they never reach the count.
local MASKED = [[
[(code_span) (link_destination) (uri_autolink) (email_autolink) (html_tag) (backslash_escape)] @masked
]]

---Whether position `a` comes before position `b`.
---@param a blink_pairs.Pos
---@param b blink_pairs.Pos
---@return boolean
local function before(a, b)
  return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
end

---Whether `pos` falls inside the end-exclusive `range`.
---@param range Range4
---@param pos blink_pairs.Pos
---@return boolean
local function within(range, pos)
  return not before(pos, { range[1], range[2] }) and before(pos, { range[3], range[4] })
end

---Whether `pos` falls inside any of `ranges`.
---@param ranges Range4[]
---@param pos blink_pairs.Pos
---@return boolean
local function masked(ranges, pos)
  for _, range in ipairs(ranges) do
    if within(range, pos) then
      return true
    end
  end
  return false
end

---The markdown_inline tree of every paragraph in `buf` that overlaps rows
---`top` to `bot`, or none when `buf` isn't markdown.
---@param buf integer
---@param top integer 0-based
---@param bot integer 0-based, exclusive
---@return TSTree[]
local function paragraphs(buf, top, bot)
  local parser = vim.treesitter.get_parser(buf)
  if not parser or parser:lang() ~= "markdown" then
    return {}
  end
  parser:parse({ top, bot })
  local inline = parser:children().markdown_inline
  -- Paragraphs outside the range keep whatever tree an earlier parse left them.
  return vim.tbl_filter(function(tree)
    local sr, _, er = tree:root():range()
    return sr < bot and er >= top
  end, inline and vim.tbl_values(inline:trees()) or {})
end

---The paragraph holding `pos`: the last to start at or before it on a row it
---spans. A paragraph's node stops short of trailing whitespace, where the
---cursor sits after typing a space, and table cells share a row.
---@param buf integer
---@param pos blink_pairs.Pos
---@return TSTree?
local function paragraph_at(buf, pos)
  local best, best_start
  for _, tree in ipairs(paragraphs(buf, pos[1], pos[1] + 1)) do
    local sr, sc, er = tree:root():range()
    local start = { sr, sc }
    if not before(pos, start) and pos[1] <= er and (not best_start or before(best_start, start)) then
      best, best_start = tree, start
    end
  end
  return best
end

---The ranges of a paragraph whose delimiters are literal text.
---@param buf integer
---@param tree TSTree
---@return Range4[]
local function masked_ranges(buf, tree)
  local query = vim.treesitter.query.parse("markdown_inline", MASKED)
  local ranges = {}
  for _, node in query:iter_captures(tree:root(), buf) do
    ranges[#ranges + 1] = { node:range() }
  end
  return ranges
end

---Every delimiter in one range of `buf`, with its position, in buffer order.
---@param buf integer
---@param range Range4
---@return { pos: blink_pairs.Pos, char: string }[]
local function scan(buf, range)
  local hits = {}
  local lines = vim.api.nvim_buf_get_text(buf, range[1], range[2], range[3], range[4], {})
  for i, line in ipairs(lines) do
    local row, offset = range[1] + i - 1, i == 1 and range[2] or 0
    local col = line:find(DELIMITER)
    while col do
      hits[#hits + 1] = { pos = { row, offset + col - 1 }, char = line:sub(col, col) }
      col = line:find(DELIMITER, col + 1)
    end
  end
  return hits
end

---Every counted delimiter in a paragraph, by character, in buffer order, plus
---the ranges left out of the count.
---@param buf integer
---@param tree TSTree
---@return table<string, blink_pairs.Pos[]> found
---@return Range4[] masks
local function delimiters(buf, tree)
  local masks = masked_ranges(buf, tree)
  local found = {}
  -- Included ranges skip the `> ` of a blockquote's continuation lines.
  for _, range in ipairs(tree:included_ranges(false)) do
    for _, hit in ipairs(scan(buf, range)) do
      if not masked(masks, hit.pos) then
        found[hit.char] = found[hit.char] or {}
        table.insert(found[hit.char], hit.pos)
      end
    end
  end
  return found, masks
end

---Whether `text` is one of the delimiters this module counts.
---@param text string
---@return boolean
function M.tracks(text)
  return #text == 1 and CHARS:find(text, 1, true) ~= nil
end

---Positions of the delimiters on rows `top` to `bot` of `buf` that have no
---partner, in buffer order. Each paragraph reaching into the range counts
---whole.
---@param buf integer
---@param top integer 0-based
---@param bot integer 0-based, exclusive
---@return blink_pairs.Pos[]
function M.positions(buf, top, bot)
  local result = {}
  for _, tree in ipairs(paragraphs(buf, top, bot)) do
    for _, found in pairs((delimiters(buf, tree))) do
      local last = found[#found]
      if #found % 2 == 1 and last[1] >= top and last[1] < bot then
        result[#result + 1] = last
      end
    end
  end
  table.sort(result, before)
  return result
end

---Whether a `char` span is open at a position: an odd number of counted
---`char`s precede it in its paragraph.
---@param buf integer
---@param row integer 0-based
---@param col integer 0-based byte column
---@param char string
---@return boolean? open nil outside markdown prose, or inside literal text
function M.span_open(buf, row, col, char)
  local pos = { row, col }
  local tree = paragraph_at(buf, pos)
  if not tree then
    return nil
  end
  local found, masks = delimiters(buf, tree)
  if masked(masks, pos) then
    return nil
  end
  local preceding = vim.tbl_filter(function(p)
    return before(p, pos)
  end, found[char] or {})
  return #preceding % 2 == 1
end

return M
