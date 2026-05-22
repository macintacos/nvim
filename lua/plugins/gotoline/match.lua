---@class gotoline.Match
---@field path string
---@field score integer
---@field positions integer[]

local M = {}

---@param path string
---@return string
local function basename(path)
  return path:match("[^/]+$") or path
end

---Compute a basename-priority bonus.
---@param path string
---@param query string
---@return integer
local function basename_bonus(path, query)
  local base = basename(path):lower()
  local q = query:lower()
  if base == q then
    return 10000
  end
  if base:sub(1, #q) == q then
    return 5000
  end
  if base:find(q, 1, true) then
    return 1000
  end
  -- Otherwise: any match must be in the dirname portion.
  return 0
end

---Rank paths by fuzzy match against query, with basename-first priority.
---@param query string
---@param paths string[]
---@return gotoline.Match[]
function M.rank(query, paths)
  if query == "" or #paths == 0 then
    return {}
  end

  -- matchfuzzypos returns { matched_paths, positions, scores }
  local ok, raw = pcall(vim.fn.matchfuzzypos, paths, query)
  if not ok or not raw or not raw[1] then
    return {}
  end

  local matched, positions, scores = raw[1], raw[2], raw[3]

  local results = {}
  for i, path in ipairs(matched) do
    results[#results + 1] = {
      path = path,
      positions = positions[i] or {},
      score = (scores[i] or 0) + basename_bonus(path, query),
    }
  end

  -- Sort by score, breaking ties with shorter paths (more specific matches).
  table.sort(results, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    return #a.path < #b.path
  end)

  return results
end

return M
