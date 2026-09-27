---Inline tests a file's syntax marks where its symbol names cannot: a Rust item under `#[test]`,
---`#[<path>::test]` or `#[cfg(test)]`, and a TypeScript `if (import.meta.vitest) { … }` block.
---
---Reads text, never a buffer, so a file only the sidebar loaded parses the same as one on screen.

local M = {}

---@type table<string, string> Treesitter language by file extension.
local LANGS = { rs = "rust", ts = "typescript", mts = "typescript", cts = "typescript", tsx = "tsx" }

-- `@test` is an attribute, standing for the item it sits on, or a block whose lines are all tests. Separate
-- patterns, not one alternation: predicates bind to a whole pattern, so shared captures would have to match all.
local RUST = [[
((attribute_item (attribute . (identifier) @name .)) @test (#eq? @name "test"))
((attribute_item (attribute . (scoped_identifier name: (identifier) @name))) @test (#eq? @name "test"))
((attribute_item
  (attribute . (identifier) @name arguments: (token_tree . (identifier) @arg .))) @test
  (#eq? @name "cfg") (#eq? @arg "test"))
]]
local VITEST = [[
(if_statement
  condition: (parenthesized_expression
    (member_expression object: (meta_property) property: (property_identifier) @name))
  consequence: (statement_block) @test
  (#eq? @name "vitest"))
]]
---@type table<string, string> By treesitter language.
local QUERIES = { rust = RUST, typescript = VITEST, tsx = VITEST }

---The item an attribute applies to: the next sibling past any further attributes and comments.
---@param node TSNode
---@return TSNode?
local function item_after(node)
  local item = node:next_named_sibling()
  while item and (item:type() == "attribute_item" or item:type():find("comment")) do
    item = item:next_named_sibling()
  end
  return item
end

---Lines of `source` holding tests, 1-based and inclusive.
---@param source string
---@param lang string
---@return { [1]: integer, [2]: integer }[]
local function regions(source, lang)
  -- A missing parser, or one whose grammar lacks these nodes, leaves the name rules to it.
  local ok, query = pcall(vim.treesitter.query.parse, lang, QUERIES[lang])
  if not ok or not query then
    return {}
  end
  local root = vim.treesitter.get_string_parser(source, lang):parse()[1]:root()
  local found = {}
  for id, node in query:iter_captures(root, source) do
    if query.captures[id] == "test" then
      local first, _, last = (node:type() == "attribute_item" and item_after(node) or node):range()
      found[#found + 1] = { first + 1, last + 1 }
    end
  end
  return found
end

---Flag the `items` inside an inline test that `path`'s syntax marks, whatever their names. An item counts by its
---name's line, which lies inside the marked item whether or not a server's range for it takes in the attributes.
---@param items { lnum: integer, test: true? }[] Read from `source`; flagged in place.
---@param path string Repo-relative; its extension picks the grammar.
---@param source string
function M.mark(items, path, source)
  local lang = LANGS[path:match("%.(%w+)$")]
  if not lang then
    return
  end
  local found = regions(source, lang)
  for _, item in ipairs(items) do
    item.test = vim.iter(found):any(function(r)
      return r[1] <= item.lnum and item.lnum <= r[2]
    end) or nil
  end
end

return M
