-- Persistent path -> filetype map, stored as JSON on disk.
-- Kept separate from init.lua so the disk round-trip is testable in isolation
-- (no Snacks / vim.bo coupling).
local M = {}

---Default on-disk store location. Lives in stdpath("state") — the XDG home for
---persistent, non-regenerable user data (unlike "cache", which may be wiped).
---The distinct "ftchooser" name avoids collisions with other tooling.
---@return string
function M.path()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "ftchooser.json")
end

---Read the path->ft map from `file`. Missing or corrupt file yields {}.
---@param file string
---@return table<string, string>
function M.load(file)
  local fd = io.open(file, "r")
  if not fd then
    return {}
  end
  local content = fd:read("*a")
  fd:close()
  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= "table" then
    return {}
  end
  return data
end

---Overwrite `file` with `map` encoded as JSON.
---@param file string
---@param map table<string, string>
function M.save(file, map)
  local fd = assert(io.open(file, "w"))
  fd:write(vim.json.encode(map))
  fd:close()
end

---Remember `ft` for `key` in the store at `file`.
---@param file string
---@param key string
---@param ft string
function M.set(file, key, ft)
  local map = M.load(file)
  map[key] = ft
  M.save(file, map)
end

---Look up the remembered filetype for `key` (nil if none).
---@param file string
---@param key string
---@return string?
function M.get(file, key)
  return M.load(file)[key]
end

return M
