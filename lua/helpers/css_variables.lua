---Keeps css-variables-language-server's completions to CSS.

local M = {}

---@type string[]
local STYLESHEETS = { "css", "scss", "less" }

---Whether the cursor is in CSS: a stylesheet buffer, or CSS injected into another
---language, such as a Svelte `<style>` block.
---@param buf integer
---@param row integer 0-based
---@param col integer 0-based byte column
---@return boolean
local function in_css(buf, row, col)
  if vim.list_contains(STYLESHEETS, vim.bo[buf].filetype) then
    return true
  end
  local parser = vim.treesitter.get_parser(buf)
  if not parser then
    return false
  end
  -- A zero-width range misses an injection that ends at the cursor, so it would stay unparsed.
  parser:parse({ row, math.max(col - 1, 0), row, col })
  return parser:language_for_range({ row, col, row, col }):lang() == "css"
end

---`items` without the `css_variables` client's ones unless the cursor is in CSS. For
---blink.cmp's `lsp` provider as its `transform_items`.
---@param ctx blink.cmp.Context
---@param items blink.cmp.CompletionItem[]
---@return blink.cmp.CompletionItem[]
function M.transform_items(ctx, items)
  local others = vim.tbl_filter(function(item)
    return item.client_name ~= "css_variables"
  end, items)
  -- blink types these as plain numbers; they are a buffer handle and nvim_win_get_cursor().
  local buf = ctx.bufnr --[[@as integer]]
  local row, col = unpack(ctx.cursor --[[@as [integer, integer] ]])
  if #others == #items or in_css(buf, row - 1, col) then
    return items
  end
  return others
end

return M
