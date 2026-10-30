---Finds the CSS classes a Svelte component or stylesheet defines and uses, from its
---source text alone.

local M = {}

---@alias svelte_css.Range [integer, integer, integer, integer] 0-based `{ start_row, start_col, end_row, end_col }`, byte columns

---@class svelte_css.Site
---@field name string
---@field range svelte_css.Range

---@class svelte_css.Definition : svelte_css.Site
---@field rule string The whole rule the selector heads, dedented
---@field rule_start integer Byte offset of the rule, which identifies it within its file
---@field global boolean Inside `:global(…)`, so it styles markup in every component
---@field subject boolean In its selector's rightmost compound, so the rule styles the element carrying the class

---@class svelte_css.Use : svelte_css.Site
---@field component boolean On a component's tag, where it passes a prop that its own file's scoped rules do not reach

---@class svelte_css.Classes
---@field definitions svelte_css.Definition[]
---@field uses svelte_css.Use[]

---@alias svelte_css.Lang "svelte"|"css"

---Only `<style>` holds classes, so the stock query's JavaScript injections would be
---parsed for nothing, and they cost four times the CSS.
---@type table<string, string>
local INJECTIONS = { svelte = '((style_element (raw_text) @injection.content) (#set! injection.language "css"))' }

---@type table<string, true>
local COMBINATORS =
  { descendant_selector = true, child_selector = true, adjacent_sibling_selector = true, sibling_selector = true }

---Pseudo-classes whose argument still matches the element itself, unlike `:not(…)` or `:has(…)`.
---@type table<string, true>
local SAME_ELEMENT = { global = true, is = true, where = true }

---Each whitespace-separated class in a `class` attribute value. A token that touches
---`{…}` is dynamic, so it is skipped whole.
---@param value string
---@param row integer
---@param col integer
---@return svelte_css.Site[]
local function value_classes(value, row, col)
  local sites = {}
  local depth, braced = 0, false
  ---@type { i: integer, row: integer, col: integer }?
  local start
  for i = 1, #value + 1 do
    local c = value:sub(i, i)
    if depth == 0 and (c == "" or c:match("%s")) then
      if start and not braced then
        local name = value:sub(start.i, i - 1)
        table.insert(sites, { name = name, range = { start.row, start.col, start.row, start.col + #name } })
      end
      start, braced = nil, false
    else
      start = start or { i = i, row = row, col = col }
      if c == "{" then
        depth, braced = depth + 1, true
      elseif c == "}" then
        depth, braced = math.max(depth - 1, 0), true
      end
    end
    if c == "\n" then
      row, col = row + 1, 0
    else
      col = col + 1
    end
  end
  return sites
end

---Classes in one `class` attribute or `class:` directive.
---@param attr_name TSNode
---@param text string
---@return svelte_css.Site[]
local function attribute_classes(attr_name, text)
  local attr = vim.treesitter.get_node_text(attr_name, text)
  if attr == "class" then
    local value = attr_name:next_named_sibling()
    if value and value:type() == "quoted_attribute_value" then
      value = value:named_child(0)
    end
    if not value then
      return {}
    end
    local row, col = value:range()
    return value_classes(vim.treesitter.get_node_text(value, text), row, col)
  elseif vim.startswith(attr, "class:") then
    local row, col = attr_name:range()
    return { { name = attr:sub(7), range = { row, col + 6, row, col + #attr } } }
  end
  return {}
end

---Whether an attribute sits on a component's tag, which is capitalized or dotted.
---@param attr_name TSNode
---@param text string
---@return boolean
local function on_component(attr_name, text)
  local attribute = attr_name:parent()
  local tag = attribute and attribute:parent()
  local name = tag and tag:named_child(0)
  local tag_name = name and vim.treesitter.get_node_text(name, text) or ""
  return (tag_name:find("^%u") or tag_name:find(".", 1, true)) ~= nil
end

---Classes in the markup's `class` attributes and `class:` directives.
---@param root TSNode
---@param text string
---@return svelte_css.Use[]
local function markup_uses(root, text)
  local uses = {}
  local query = vim.treesitter.query.parse("svelte", "(attribute (attribute_name) @name)")
  for _, node in query:iter_captures(root, text) do
    local component = on_component(node, text)
    for _, site in ipairs(attribute_classes(node, text)) do
      table.insert(uses, { name = site.name, range = site.range, component = component })
    end
  end
  return uses
end

---The name of the pseudo-class `node` holds the arguments of, such as `global` for
---`:global(…)`, or nil when `node` is no argument list.
---@param node TSNode
---@param text string
---@return string?
local function pseudo_class_name(node, text)
  -- The name sits just before its arguments: `p:global(…)` has the `p` in front.
  local name = node:type() == "arguments" and node:prev_named_sibling()
  return name and vim.treesitter.get_node_text(name, text) or nil
end

---Whether a class selector sits inside a `:global(…)` argument list.
---@param node TSNode
---@param text string
---@return boolean
local function is_global(node, text)
  local parent = node:parent()
  while parent and parent:type() ~= "rule_set" do
    if pseudo_class_name(parent, text) == "global" then
      return true
    end
    parent = parent:parent()
  end
  return false
end

---Whether the class selector sits in its selector's rightmost compound, outside any
---pseudo-class that matches another element.
---@param node TSNode
---@param text string
---@return boolean
local function is_subject(node, text)
  local child, parent = node, node:parent()
  while parent and parent:type() ~= "selectors" do
    local rightmost = parent:named_child(parent:named_child_count() - 1)
    if COMBINATORS[parent:type()] and not (rightmost and rightmost:equal(child)) then
      return false
    end
    local pseudo_name = pseudo_class_name(parent, text)
    if pseudo_name and not SAME_ELEMENT[pseudo_name] then
      return false
    end
    child, parent = parent, parent:parent()
  end
  return true
end

---The rule's text with its first line's indent restored, so dedenting treats every
---line alike.
---@param rule TSNode
---@param text string
---@return string
local function rule_text(rule, text)
  local _, col, start = rule:start()
  local line_start = start - col + 1
  -- Anchored, so a minified line's long prefix is never copied.
  local _, blank_end = text:find("^[ \t]*", line_start)
  local indent = blank_end == start and text:sub(line_start, start) or ""
  return (vim.text.indent(0, indent .. vim.treesitter.get_node_text(rule, text)))
end

---@param node TSNode
---@return TSNode?
local function enclosing_rule(node)
  local parent = node:parent()
  while parent and parent:type() ~= "rule_set" do
    parent = parent:parent()
  end
  return parent
end

---Class selectors in a CSS tree.
---@param root TSNode
---@param text string
---@return svelte_css.Definition[]
local function css_definitions(root, text)
  local definitions = {}
  -- `class_selector` alone: a pseudo-class name such as `hover` is a `class_name` too.
  local query = vim.treesitter.query.parse("css", "(class_selector (class_name) @name)")
  for _, node in query:iter_captures(root, text) do
    local rule = enclosing_rule(node)
    if rule then
      local srow, scol, erow, ecol = node:range()
      local _, _, rule_start = rule:start()
      table.insert(definitions, {
        name = vim.treesitter.get_node_text(node, text),
        range = { srow, scol, erow, ecol },
        rule = rule_text(rule, text),
        rule_start = rule_start,
        global = is_global(node, text),
        subject = is_subject(node, text),
      })
    end
  end
  return definitions
end

---The classes `text` defines in its selectors and uses in its markup.
---@param text string Source of a Svelte component or a stylesheet
---@param lang svelte_css.Lang
---@return svelte_css.Classes
function M.parse(text, lang)
  local parser = vim.treesitter.get_string_parser(text, lang, { injections = INJECTIONS })
  parser:parse(true)
  local css = lang == "css" and parser or parser:children().css
  local definitions = {}
  for _, tree in ipairs(css and css:trees() or {}) do
    vim.list_extend(definitions, css_definitions(tree:root(), text))
  end
  local uses = lang == "svelte" and markup_uses(parser:trees()[1]:root(), text) or {}
  return { definitions = definitions, uses = uses }
end

return M
