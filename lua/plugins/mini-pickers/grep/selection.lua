---What a key does to the live grep's selected query.
---
---The picker reopens on the last query drawn as selected, so the next search
---can start by just typing. mini.pick's prompt has no selection; the grep picker
---emulates one and asks this module what each key means for it.

local M = {}

local CLEAR = { vim.keycode("<BS>"), vim.keycode("<C-w>") }
local EDIT = { vim.keycode("<Left>"), vim.keycode("<Right>") }

---@alias mini-pickers.grep.selection.Action
---| "replace" # Clear the query, then let the key type into it.
---| "clear" # Clear the query and swallow the key.
---| "edit" # Keep the query and let the key move the caret.
---| "drop" # Keep the query and let the key do what it does.

---Classify a raw key as typed while the query is selected.
---@param key string Raw keycode, as `vim.on_key` reports it.
---@return mini-pickers.grep.selection.Action
function M.classify(key)
  if vim.tbl_contains(CLEAR, key) then
    return "clear"
  elseif vim.tbl_contains(EDIT, key) then
    return "edit"
  elseif vim.fn.strchars(key) == 1 and key:byte() ~= 0x80 and vim.fn.strtrans(key) == key then
    return "replace"
  end
  return "drop"
end

return M
