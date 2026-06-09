---@module 'blink.cmp'
---A blink.cmp source that bridges the current buffer's `omnifunc` into the
---completion menu, so `<C-x><C-o>` suggestions show up like any other source.
---@class blink.cmp.Source
local source = {}

---Vim complete-item `kind` letters → LSP CompletionItemKind.
---@type table<string, integer>
local KIND = {
  v = 6, -- Variable
  f = 3, -- Function
  m = 5, -- Field (member)
  t = 7, -- Class (type)
  d = 21, -- Constant (define)
}

---Normalize an omnifunc result into blink completion items.
---Handles the three shapes omnifunc may return: a list of strings, a list of
---complete-item dicts (`word`/`abbr`/`menu`/`info`/`kind`), or `{ words = ... }`.
---@param result any Raw value returned by the omnifunc in results mode.
---@return lsp.CompletionItem[]
local function to_items(result)
  local words = result
  if type(result) == "table" and result.words ~= nil then
    words = result.words
  end
  if type(words) ~= "table" then
    return {}
  end

  local items = {}
  for _, w in ipairs(words) do
    if type(w) == "string" then
      items[#items + 1] = { label = w, insertText = w }
    elseif type(w) == "table" and w.word then
      local item = {
        label = (w.abbr ~= nil and w.abbr ~= "") and w.abbr or w.word,
        insertText = w.word,
      }
      if w.menu ~= nil and w.menu ~= "" then
        item.detail = w.menu
      end
      if w.info ~= nil and w.info ~= "" then
        item.documentation = w.info
      end
      if w.kind ~= nil and KIND[w.kind] then
        item.kind = KIND[w.kind]
      end
      items[#items + 1] = item
    end
  end
  return items
end

-- Exposed for testing only.
source._to_items = to_items

---@type { items: lsp.CompletionItem[], is_incomplete_forward: boolean, is_incomplete_backward: boolean }
local EMPTY_RESPONSE = { items = {}, is_incomplete_forward = false, is_incomplete_backward = false }

---@return blink.cmp.Source
function source.new()
  return setmetatable({}, { __index = source })
end

---Only active when the buffer actually has an omnifunc to call.
---@return boolean
function source:enabled()
  return vim.bo.omnifunc ~= ""
end

---Drive the buffer's omnifunc and return its suggestions as blink items.
---Mirrors how the editor itself calls omnifunc: first in findstart mode to
---locate the base column, then in results mode with the typed prefix.
---@param ctx { line: string, cursor: integer[], bufnr: integer }
---@param callback fun(response: { items: lsp.CompletionItem[], is_incomplete_forward: boolean, is_incomplete_backward: boolean })
function source:get_completions(ctx, callback)
  local omnifunc = vim.bo.omnifunc
  if omnifunc == "" then
    callback(EMPTY_RESPONSE)
    return
  end

  local ok, start_col = pcall(vim.fn.call, omnifunc, { 1, "" })
  if not ok or type(start_col) ~= "number" or start_col < 0 then
    callback(EMPTY_RESPONSE)
    return
  end

  local base = ctx.line:sub(start_col + 1, ctx.cursor[2])
  local got, result = pcall(vim.fn.call, omnifunc, { 0, base })
  if not got then
    callback(EMPTY_RESPONSE)
    return
  end

  local items = to_items(result)
  -- Anchor each replacement at the column omnifunc reported, so accepting an
  -- item overwrites exactly the base it was completing.
  local row = ctx.cursor[1] - 1
  for _, item in ipairs(items) do
    item.textEdit = {
      newText = item.insertText,
      range = {
        start = { line = row, character = start_col },
        ["end"] = { line = row, character = ctx.cursor[2] },
      },
    }
  end

  -- omnifunc results depend on the typed prefix, so re-query as it changes.
  callback({ items = items, is_incomplete_forward = true, is_incomplete_backward = true })
end

return source
