---Which LSP symbol kinds are worth listing, per filetype.
---
---Both symbol pickers ask the same question — "what counts as an outline entry
---in this buffer?" — so they ask it here rather than each keeping its own rule.

local M = {}

-- Servers emit a symbol per table key, so without this a Lua file's outline is
-- mostly `[1]`, `[2]`, and `desc`.
local DECLARATIONS = {
  Class = true,
  Constant = true,
  Constructor = true,
  Enum = true,
  EnumMember = true,
  Event = true,
  Field = true,
  Function = true,
  Interface = true,
  Method = true,
  Module = true,
  Namespace = true,
  Package = true,
  Property = true,
  Struct = true,
  TypeParameter = true,
  Variable = true,
}

-- Data filetypes are exempt because there Object/Array/String *are* the
-- structure — the same carve-out the old snacks picker needed for toml.
local KEEP_EVERY_KIND = { toml = true, json = true, jsonc = true, yaml = true, markdown = true }

-- Kinds a server emits for structure rather than for declarations. lua_ls
-- reports every `if`/`for`/`else`/`elseif` block as a Package symbol — 55 of
-- the 323 symbols in this repo's plugin/mini.lua — which buries the real
-- entries and turns a breadcrumb into "make_symbol_show › return › for".
-- Dropping Package outright would cost the languages that use it for actual
-- packages, so the exclusion is scoped by filetype.
local EXCLUDE = { lua = { Package = true } }

---Kinds the narrowed jump pickers list, regardless of filetype.
---@type table<string, true>
M.FUNCTIONS = { Function = true, Method = true }

---@type table<string, true>
M.VARIABLES = { Constant = true, Field = true, Property = true, Variable = true }

---Kinds to keep for `ft`, or `nil` to keep every kind.
---@param ft string
---@return table<string, true>?
function M.for_filetype(ft)
  if KEEP_EVERY_KIND[ft] then
    return nil
  end
  local keep = vim.deepcopy(DECLARATIONS)
  for kind in pairs(EXCLUDE[ft] or {}) do
    keep[kind] = nil
  end
  return keep
end

return M
