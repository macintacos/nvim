---Live grep ranking: demote the files you are probably not looking for.
---
---Hits stay grouped by file, in rg's order within a file, because the header
---renderer draws one header per run of equal paths. Files sort by tier, then by
---the sort mode, then by path.

local M = {}

---Tiers past the first, highest wins: a test inside `node_modules/` is a
---dependency. `dirs` match any directory segment; `files` are globs on the
---basename. Grow the lists here; there is no user config.
M.TIERS = {
  {
    tier = 2,
    dirs = { "tests", "test", "spec", "__tests__", "testdata" },
    files = { "*_spec.*", "*_test.*", "*.test.*", "*.spec.*", "test_*.py", "conftest.py", "*.bats" },
  },
  {
    tier = 3,
    dirs = {
      "dist",
      "build",
      "out",
      "target",
      ".next",
      "coverage",
      "__pycache__",
      "node_modules",
      ".venv",
      "venv",
      "vendor",
      "site-packages",
      ".tox",
    },
    files = { "*.lock", "*-lock.json", "*-lock.yaml", "go.sum", "bun.lockb", "*.min.*", "*.map" },
  },
}

---@alias mini-pickers.grep.rank.Sort "path"|"nearest"|"hits"|"recent"

---Sort modes in the order `<M-t>` cycles them; the first is the default.
---@type [mini-pickers.grep.rank.Sort, mini-pickers.grep.rank.Sort, mini-pickers.grep.rank.Sort, mini-pickers.grep.rank.Sort]
M.SORTS = { "path", "nearest", "hits", "recent" }

local compiled = vim.tbl_map(function(t)
  local dirs = {}
  for _, d in ipairs(t.dirs) do
    dirs[d] = true
  end
  return { tier = t.tier, dirs = dirs, files = vim.tbl_map(vim.glob.to_lpeg, t.files) }
end, M.TIERS)

---@param t { dirs: table<string, boolean>, files: vim.lpeg.Pattern[] }
---@param segments string[] Directory segments.
---@param name string Basename.
---@return boolean
local function matches(t, segments, name)
  for _, s in ipairs(segments) do
    if t.dirs[s] then
      return true
    end
  end
  for _, p in ipairs(t.files) do
    if p:match(name) then
      return true
    end
  end
  return false
end

---Tier of a path relative to the search root: 1 implementation and config,
---2 tests, 3 lockfiles, build output, and local dependencies.
---@param path string
---@return integer
function M.tier(path)
  local segments = vim.split(path, "/", { plain = true })
  local name = table.remove(segments)
  local best = 1
  for _, t in ipairs(compiled) do
    if matches(t, segments, name) then
      best = math.max(best, t.tier)
    end
  end
  return best
end

---The sort mode after `sort`, wrapping around.
---@param sort mini-pickers.grep.rank.Sort
---@return mini-pickers.grep.rank.Sort
function M.next_sort(sort)
  for i, s in ipairs(M.SORTS) do
    if s == sort then
      return M.SORTS[i + 1] or M.SORTS[1]
    end
  end
  return M.SORTS[1]
end

---@param path string
---@return string[]
local function segments(path)
  local dir = vim.fs.dirname(path)
  return dir == "." and {} or vim.split(dir, "/", { plain = true })
end

---How many directory segments separate two files' directories.
---@param a string
---@param b string
---@return integer
local function distance(a, b)
  local da, db = segments(a), segments(b)
  local common = 0
  while common < #da and common < #db and da[common + 1] == db[common + 1] do
    common = common + 1
  end
  return #da + #db - 2 * common
end

---@class mini-pickers.grep.rank.Context
---@field sort mini-pickers.grep.rank.Sort
---@field origin? string The origin buffer's path, relative like the hits.
---@field recent? table<string, integer> Path to recency rank, lower is newer.

---Sort key for the mode, lower first; nil means every file ties.
---@param ctx mini-pickers.grep.rank.Context
---@return (fun(path: string, count: integer): number)?
local function mode_key(ctx)
  if ctx.sort == "nearest" and ctx.origin then
    return function(path)
      return distance(path, ctx.origin)
    end
  elseif ctx.sort == "hits" then
    return function(_, count)
      return -count
    end
  elseif ctx.sort == "recent" then
    local recent = ctx.recent or {}
    return function(path)
      return recent[path] or math.huge
    end
  end
end

---Rank rg hits: files by tier, then the sort mode, then path.
---@param items string[] rg hits as `path\0lnum\0col\0text`.
---@param ctx mini-pickers.grep.rank.Context
---@return string[]
function M.order(items, ctx)
  local groups, by_path, stray = {}, {}, {}
  for _, item in ipairs(items) do
    local path = item:match("^(.-)%z%d+%z")
    if not path then
      stray[#stray + 1] = item
    elseif by_path[path] then
      table.insert(by_path[path].items, item)
    else
      by_path[path] = { path = path, tier = M.tier(path), items = { item } }
      groups[#groups + 1] = by_path[path]
    end
  end

  local key = mode_key(ctx)
  for _, g in ipairs(groups) do
    g.key = key and key(g.path, #g.items) or 0
  end
  table.sort(groups, function(a, b)
    if a.tier ~= b.tier then
      return a.tier < b.tier
    elseif a.key ~= b.key then
      return a.key < b.key
    end
    return a.path < b.path
  end)

  local out = {}
  for _, g in ipairs(groups) do
    vim.list_extend(out, g.items)
  end
  return vim.list_extend(out, stray)
end

return M
