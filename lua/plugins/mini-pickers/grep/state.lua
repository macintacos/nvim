---The live grep's saved settings, and the rg command they produce.
---
---One table holds the filters, sort mode, ignored-paths toggle, regex method,
---and last query. It is saved JSON-encoded in an uppercase String global, so
---`:mksession` (`sessionoptions` has `globals`) keeps it with the project's
---session. Everything here is pure, returning new state rather than changing
---what it is given; the grep picker reads and writes the global.

local rank = require("plugins.mini-pickers.grep.rank")

local M = {}

---@class mini-pickers.grep.state.Filter
---@field kind "exclude"|"include"
---@field path string Relative to Neovim's cwd, no trailing slash.
---@field dir boolean Whether `path` named a directory when it was added.

---@class mini-pickers.grep.state.State
---@field filters mini-pickers.grep.state.Filter[]
---@field sort mini-pickers.grep.rank.Sort
---@field ignored boolean Also search paths rg ignores.
---@field method "regex"|"plain"
---@field query string

---The state of a grep nobody has changed.
---@return mini-pickers.grep.state.State
function M.default()
  return { filters = {}, sort = rank.SORTS[1], ignored = false, method = "regex", query = "" }
end

---Encode the state for the String global it is saved in.
---@param state mini-pickers.grep.state.State
---@return string
function M.encode(state)
  return vim.json.encode(state)
end

---@param f any
---@return boolean
local function is_filter(f)
  return type(f) == "table" and (f.kind == "exclude" or f.kind == "include") and type(f.path) == "string"
end

---Decode a saved value, keeping each valid field and defaulting the rest.
---@param str string?
---@return mini-pickers.grep.state.State
function M.decode(str)
  local state = M.default()
  local ok, raw = pcall(vim.json.decode, str or "")
  if not ok or type(raw) ~= "table" or vim.islist(raw) then
    return state
  end
  if type(raw.filters) == "table" then
    state.filters = vim.tbl_map(function(f)
      -- Filters saved before `dir` was recorded were drawn as directories.
      return { kind = f.kind, path = f.path, dir = f.dir ~= false }
    end, vim.tbl_filter(is_filter, raw.filters))
  end
  if vim.tbl_contains(rank.SORTS, raw.sort) then
    state.sort = raw.sort
  end
  if type(raw.ignored) == "boolean" then
    state.ignored = raw.ignored
  end
  if raw.method == "regex" or raw.method == "plain" then
    state.method = raw.method
  end
  if type(raw.query) == "string" then
    state.query = raw.query
  end
  return state
end

---@param path string
---@return string
local function normalize(path)
  return (vim.fs.normalize(vim.trim(path)):gsub("^%./", ""):gsub("/+$", ""))
end

---A copy of the state with the filter added, unless it is empty or already there.
---@param state mini-pickers.grep.state.State
---@param kind "exclude"|"include"
---@param path string
---@param dir boolean Whether `path` names a directory.
---@return mini-pickers.grep.state.State
function M.add_filter(state, kind, path, dir)
  local out = vim.deepcopy(state)
  path = normalize(path)
  if path == "" or path == "." then
    return out
  end
  for _, f in ipairs(out.filters) do
    if f.kind == kind and f.path == path then
      return out
    end
  end
  table.insert(out.filters, { kind = kind, path = path, dir = dir })
  return out
end

---The defaults, keeping the query.
---@param state mini-pickers.grep.state.State
---@return mini-pickers.grep.state.State
function M.reset(state)
  local fresh = M.default()
  fresh.query = state.query
  return fresh
end

---@param path string
---@return string
local function escape_glob(path)
  return (path:gsub("[%*%?%[%]{}\\]", "\\%0"))
end

---Paths of the filters of one kind, relative to the directory rg runs in.
---Filters outside it are dropped.
---@param filters mini-pickers.grep.state.Filter[]
---@param kind "exclude"|"include"
---@param root string Neovim's cwd, absolute.
---@param cwd string The picker's cwd, absolute.
---@return string[]
local function rebased(filters, kind, root, cwd)
  local out = {}
  for _, f in ipairs(filters) do
    local rel = f.kind == kind and vim.fs.relpath(cwd, vim.fs.joinpath(root, f.path))
    if rel and rel ~= "." then
      out[#out + 1] = rel
    end
  end
  return out
end

---rg globs for the excludes, anchored to the directory rg runs in.
---@param filters mini-pickers.grep.state.Filter[]
---@param root string Neovim's cwd, absolute.
---@param cwd string The picker's cwd, absolute.
---@return string[]
function M.globs(filters, root, cwd)
  return vim.tbl_map(function(rel)
    return "!/" .. escape_glob(rel)
  end, rebased(filters, "exclude", root, cwd))
end

---rg path arguments for the includes. A positive `--glob` would override
---rg's ignore files, so includes are searched as paths instead.
---@param filters mini-pickers.grep.state.Filter[]
---@param root string Neovim's cwd, absolute.
---@param cwd string The picker's cwd, absolute.
---@return string[]
function M.paths(filters, root, cwd)
  return rebased(filters, "include", root, cwd)
end

---@class mini-pickers.grep.state.CommandOpts
---@field pattern string
---@field case "smart-case"|"ignore-case"|"case-sensitive"
---@field globs? string[] Scope and filter globs, in order.
---@field paths? string[] Paths to search instead of the whole directory.

---The rg command for one query, as mini.pick's `grep_live` builds it.
---@param state mini-pickers.grep.state.State
---@param opts mini-pickers.grep.state.CommandOpts
---@return string[]
function M.command(state, opts)
  local cmd = { "rg", "--column", "--line-number", "--no-heading", "--field-match-separator", "\\x00", "--color=never" }
  -- A single file path argument would otherwise drop the path from each hit.
  table.insert(cmd, "--with-filename")
  table.insert(cmd, state.method == "regex" and "--no-fixed-strings" or "--fixed-strings")
  if state.ignored then
    -- The rgrc adds --hidden, which would otherwise walk .git/.
    vim.list_extend(cmd, { "--no-ignore", "--glob", "!.git" })
  end
  for _, glob in ipairs(opts.globs or {}) do
    vim.list_extend(cmd, { "--glob", glob })
  end
  return vim.list_extend(vim.list_extend(cmd, { "--" .. opts.case, "--", opts.pattern }), opts.paths or {})
end

---A filter as drawn: its sign, then its path, with a slash for a directory.
---@param filter mini-pickers.grep.state.Filter
---@return string
function M.filter_text(filter)
  return (filter.kind == "exclude" and "−" or "+") .. filter.path .. (filter.dir and "/" or "")
end

local SORT_LABELS = { nearest = "nearest first", hits = "most hits first", recent = "recent first" }

---The footer name: `base` when everything is default, else what differs.
---@param state mini-pickers.grep.state.State
---@param base string The picker's name, kept in front of the differences.
---@param default string The unscoped picker's name, which drops out instead.
---@return string
function M.label(state, base, default)
  local parts = {}
  for _, f in ipairs(state.filters) do
    parts[#parts + 1] = M.filter_text(f)
  end
  parts[#parts + 1] = SORT_LABELS[state.sort]
  parts[#parts + 1] = state.ignored and "ignored" or nil
  parts[#parts + 1] = state.method ~= "regex" and "plain" or nil
  if #parts == 0 then
    return base
  end
  if base ~= default then
    table.insert(parts, 1, base)
  end
  return table.concat(parts, " ")
end

return M
