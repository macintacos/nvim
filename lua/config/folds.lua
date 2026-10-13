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

-- Text column the bar stops at, however wide the window.
local MAX_WIDTH = 100

-- The chevron 'fillchars' foldclose puts in the gutter (U+F460), repeated on the
-- line so both marks for one fold match.
local COLLAPSED = ""

-- Title of a closed import block, in place of its first import.
local IMPORTS = "imports"

-- Tree-sitter nodes that open an import block.
local IMPORT_NODES = {
  import_statement = true, -- Python, TypeScript, JavaScript
  import_from_statement = true, -- Python
  import_declaration = true, -- Go
  use_declaration = true, -- Rust
}

-- Filetypes whose language servers report the import block as a fold of kind
-- "imports". Elsewhere the window keeps its tree-sitter folds.
local IMPORT_FILETYPES = {
  go = true,
  javascript = true,
  javascriptreact = true,
  python = true,
  rust = true,
  typescript = true,
  typescriptreact = true,
}

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
  ---@type table<integer, integer?>
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
  local win = assert(vim.fn.getwininfo(vim.api.nvim_get_current_win())[1], "current window has no getwininfo entry")
  return win.width - win.textoff
end

---Whether the fold opening at `col` of `row` in the current buffer is an import
---block. Reads the tree the highlighter keeps parsed.
---@param row integer 0-indexed
---@param col integer
---@return boolean
local function opens_imports(row, col)
  local node = vim.treesitter.get_node({ pos = { row, col } })
  return node ~= nil and IMPORT_NODES[node:type()] == true
end

---'foldtext' expression: a bar standing in for the closed fold.
---@return string
function M.foldtext()
  local first, last = vim.v.foldstart, vim.v.foldend
  local text = tostring(vim.fn.getline(first))
  -- Tabs expanded so the bar starts at the same column as the block it replaces.
  local line = text:gsub("\t", (" "):rep(vim.bo.tabstop))
  local indent = line:match("^%s*")
  local hidden = last - first
  local title = opens_imports(first - 1, #text:match("^%s*")) and IMPORTS or vim.trim(line)

  return indent
    .. bar(
      ("%s %s"):format(COLLAPSED, title),
      summary(hidden, diagnostic_counts(first, last), vim.api.nvim_buf_line_count(0)),
      math.min(text_width(), MAX_WIDTH) - #indent
    )
end

---Hand the folds of the window showing `buf` to its language servers and close
---the import block, when `client` serves folding ranges for a language with
---imports.
---@param client vim.lsp.Client
---@param buf integer
function M.fold_imports(client, buf)
  local win = vim.fn.bufwinid(buf)
  if
    win == -1
    or not IMPORT_FILETYPES[vim.bo[buf].filetype]
    or not client:supports_method("textDocument/foldingRange")
  then
    return
  end
  vim.wo[win][0].foldmethod = "expr"
  vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
  -- foldclose() does nothing until vim.lsp.foldexpr() has run, and that first
  -- run only sets up the buffer's fold state on the next tick.
  vim.api.nvim_win_call(win, function()
    vim.fn.foldlevel(1)
  end)
  vim.schedule(function()
    vim.lsp.foldclose("imports", win)
  end)
end

M._bar = bar
M._summary = summary

return M
