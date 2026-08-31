-- Render a closed fold as a badge summarising what it hides, rather than as its
-- first line.
--
-- An empty 'foldtext' draws the fold's own source, which reads like an ordinary
-- line. Returning virtual-text chunks replaces the whole line instead, keeping
-- only the fold's indentation so the badge sits where the block it stands in
-- for did. Colors come from lua/config/highlights.lua.

local M = {}

-- Rounded half-blocks (U+E0B6, U+E0B4) drawn in the badge's own background
-- color, so the badge reads as a pill rather than a rectangle.
local CAP_LEFT = ""
local CAP_RIGHT = ""

-- The chevron 'fillchars' foldclose puts in the gutter (U+F460), repeated on the
-- line so both marks for one fold match.
local COLLAPSED = ""

---Diagnostic severities worth surfacing, most severe first.
---@type { level: integer, icon: string, hl: string }[]
local SEVERITIES = {
  { level = vim.diagnostic.severity.ERROR, icon = "", hl = "FoldChipError" },
  { level = vim.diagnostic.severity.WARN, icon = "", hl = "FoldChipWarn" },
}

---Leading whitespace of a line, tabs expanded so the badge sits at the same
---column as the code it replaces.
---@param lnum integer 1-indexed line
---@return string
local function indent_of(lnum)
  local ws = vim.fn.getline(lnum):match("^%s*")
  return (ws:gsub("\t", string.rep(" ", vim.bo.tabstop)))
end

---Counts of the diagnostics a fold hides, as virtual-text chunks.
---@param first integer 1-indexed first folded line
---@param last integer 1-indexed last folded line
---@return [string, string][] chunks Empty when the fold hides nothing of note
local function diagnostic_chunks(first, last)
  local counts = {}
  for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
    if diagnostic.lnum >= first - 1 and diagnostic.lnum <= last - 1 then
      counts[diagnostic.severity] = (counts[diagnostic.severity] or 0) + 1
    end
  end

  local chunks = {}
  for _, severity in ipairs(SEVERITIES) do
    local count = counts[severity.level]
    if count then
      -- A dot parts the counts from the line total, a space parts them from
      -- each other.
      chunks[#chunks + 1] = { #chunks == 0 and " · " or " ", "FoldChip" }
      chunks[#chunks + 1] = { ("%s %d"):format(severity.icon, count), severity.hl }
    end
  end
  return chunks
end

---'foldtext' expression: a badge standing in for the closed fold.
---@return [string, string][] chunks
function M.foldtext()
  local first, last = vim.v.foldstart, vim.v.foldend
  local chunks = {
    { indent_of(first), "Folded" },
    { CAP_LEFT, "FoldChipEdge" },
    { (" %s %d lines"):format(COLLAPSED, last - first + 1), "FoldChip" },
  }
  vim.list_extend(chunks, diagnostic_chunks(first, last))
  vim.list_extend(chunks, { { " ", "FoldChip" }, { CAP_RIGHT, "FoldChipEdge" } })
  return chunks
end

return M
