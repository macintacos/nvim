-- Which Go constructs can be drawn on one line, decided from the syntax tree alone.

local M = {}

---@class go-folds.inline.Opts
---@field width integer Columns the one-line form may occupy
---@field tabstop integer Columns a tab in the indentation draws as

---A stretch of one buffer line, in bytes.
---@class go-folds.inline.Piece
---@field row integer 0-indexed
---@field from integer First byte, 0-indexed
---@field to integer Byte past the last

---@class go-folds.inline.Construct
---@field first integer 0-indexed row of the header
---@field last integer 0-indexed row of the closing brace, or of a case's statement
---@field indent string The header's indentation, tabs expanded
---@field pieces go-folds.inline.Piece[] What the one line shows, in order, a space apart
---@field text string The one line

---Field naming the block of each construct that closes with a brace.
---@type table<string, string?>
local BLOCK_FIELD = {
  if_statement = "consequence",
  function_declaration = "body",
  method_declaration = "body",
  func_literal = "body",
}

---Constructs that only fold when their one statement is a `return`.
---@type table<string, true?>
local RETURNS = { function_declaration = true, method_declaration = true, func_literal = true }

---Clauses that hold their statements directly and close with no brace.
---@type table<string, true?>
local CLAUSES = { expression_case = true, default_case = true, type_case = true, communication_case = true }

---The one statement `container` holds, or nil when it holds anything else: a
---comment, a second statement, nothing.
---@param container TSNode A block or a case clause
---@return TSNode?
local function only_statement(container)
  local list
  for child in container:iter_children() do
    if child:type() == "comment" then
      return nil
    elseif child:type() == "statement_list" then
      list = child
    end
  end
  if not list or list:named_child_count() ~= 1 then
    return nil
  end
  local statement = assert(list:named_child(0), "a statement list of one has a first child")
  return statement:type() ~= "comment" and statement or nil
end

---The statement `node` folds around and the row its fold ends on, or nil when
---`node` is no construct that folds.
---@param node TSNode
---@return TSNode? statement
---@return integer? last
local function body(node)
  local kind = node:type()
  local first = node:start()
  if CLAUSES[kind] then
    return only_statement(node), first + 1
  end
  local block = BLOCK_FIELD[kind] and node:field(BLOCK_FIELD[kind])[1]
  local parent = node:parent()
  if
    not block
    or block:start() ~= first
    or block:end_() ~= first + 2
    or #node:field("alternative") > 0
    or (kind == "if_statement" and parent ~= nil and parent:type() == "if_statement")
  then
    return nil
  end
  local statement = only_statement(block)
  if statement and RETURNS[kind] and statement:type() ~= "return_statement" then
    return nil
  end
  return statement, first + 2
end

---`text` from its first non-blank byte to its last, as a piece of `row`.
---@param row integer
---@param text string
---@return go-folds.inline.Piece
local function trimmed(row, text)
  return { row = row, from = #text:match("^%s*"), to = #text:match("^(.-)%s*$") }
end

---`node` as a construct, or nil when it must stay expanded.
---@param node TSNode
---@param line fun(row: integer): string? Text of a 0-indexed row
---@param opts go-folds.inline.Opts
---@return go-folds.inline.Construct?
local function construct(node, line, opts)
  local statement, last = body(node)
  if not statement or not last then
    return nil
  end
  local first = node:start()
  local row, from, end_row, to = statement:range()
  local inner = trimmed(row, line(row) or "")
  -- The statement must be all its line holds, or joining the lines drops text.
  if row ~= first + 1 or end_row ~= row or inner.from ~= from or inner.to ~= to then
    return nil
  end

  local header = line(first) or ""
  local pieces = { trimmed(first, header), inner }
  if last > row then
    pieces[#pieces + 1] = trimmed(last, line(last) or "")
  end
  local tab = (" "):rep(opts.tabstop)
  local indent = assert(header:match("^%s*"), "every line has indentation, if empty"):gsub("\t", tab)
  local text = indent
    .. table.concat(
      vim.tbl_map(function(piece)
        return (line(piece.row) or ""):sub(piece.from + 1, piece.to)
      end, pieces),
      " "
    )
  if vim.api.nvim_strwidth(text) > opts.width then
    return nil
  end
  return { first = first, last = last, indent = indent, pieces = pieces, text = text }
end

---Append the constructs under `node` to `found`, in document order.
---@param node TSNode
---@param line fun(row: integer): string?
---@param opts go-folds.inline.Opts
---@param found go-folds.inline.Construct[]
local function collect(node, line, opts, found)
  local previous = found[#found]
  local candidate = construct(node, line, opts)
  -- Two folds cannot share a row.
  if candidate and not (previous and candidate.first <= previous.last) then
    found[#found + 1] = candidate
    return
  end
  for child in node:iter_children() do
    if child:named() then
      collect(child, line, opts, found)
    end
  end
end

---The constructs under `root` that read as one line of Go: an `if` with no
---`else`, a function that only returns, and a case clause, each around a single
---one-line statement.
---@param root TSNode
---@param line fun(row: integer): string? Text of a 0-indexed row
---@param opts go-folds.inline.Opts
---@return go-folds.inline.Construct[]
function M.constructs(root, line, opts)
  local found = {}
  collect(root, line, opts, found)
  return found
end

---`ranges` with one range per construct, reaching its last row. Servers end a
---block's range on the line before its closing brace, which a closed fold would
---leave hanging below it.
---@param ranges lsp.FoldingRange[]
---@param constructs { first: integer, last: integer }[]
---@return lsp.FoldingRange[]
function M.widen(ranges, constructs)
  local starts = {}
  for _, found in ipairs(constructs) do
    starts[found.first] = true
  end
  local widened = vim.tbl_filter(function(range)
    return not starts[range.startLine]
  end, ranges)
  for _, found in ipairs(constructs) do
    widened[#widened + 1] = { startLine = found.first, endLine = found.last }
  end
  return widened
end

return M
