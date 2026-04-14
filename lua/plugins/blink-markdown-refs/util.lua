local M = {}

---@type table<integer, string> Per-buffer cache of project root paths
local root_cache = {}

-- Invalidate cached root when switching directories
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    root_cache = {}
  end,
})

-- Evict cache entry when a buffer is deleted to prevent stale entries accumulating
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(ev)
    root_cache[ev.buf] = nil
  end,
})

---Find the project root directory for the given buffer.
---Uses git root if inside a repository, otherwise falls back to the buffer's directory.
---Results are cached per buffer and invalidated on DirChanged.
---@param bufnr? integer Buffer number (0 or nil for current buffer)
---@return string root Absolute path to the project root
function M.get_root(bufnr)
  bufnr = bufnr or 0
  local cached = root_cache[bufnr]
  if cached then
    return cached
  end

  local buf_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":h")
  local result = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true, cwd = buf_dir }):wait()
  local root = result.code == 0 and vim.trim(result.stdout) or buf_dir
  root_cache[bufnr] = root
  return root
end

---Convert a markdown heading to a GitHub-style anchor slug.
---Lowercase, strip non-alphanumeric (keep spaces/hyphens/underscores),
---collapse whitespace to hyphens, trim leading/trailing hyphens.
---@param text string Heading text (without leading `#` markers)
---@return string slug GitHub-compatible anchor fragment
function M.heading_to_anchor(text)
  return text:lower():gsub("[^%w%s%-_]", ""):gsub("%s+", "-"):gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
end

---Left-truncate a string to max_len display columns, prepending "…" if truncated.
---The ellipsis counts as 1 display column.
---@param text string Input string
---@param max_len integer Display width limit
---@return string truncated The truncated (or original) string
function M.truncate_left(text, max_len)
  if #text <= max_len then
    return text
  end
  -- "…" is 1 display column, so keep max_len - 1 ASCII chars from the right
  return "…" .. text:sub(-(max_len - 1))
end

---Smart-case plain-text search: case-insensitive when query is all lowercase,
---case-sensitive otherwise. Returns the 1-based start position, or nil.
---@param query string Search text
---@param text string Text to search within
---@return integer? start 1-based byte position of the match, or nil
function M.smart_find(query, text)
  if query == "" then
    return 1
  end
  if query == query:lower() then
    return text:lower():find(query, 1, true)
  end
  return text:find(query, 1, true)
end

---Check if query is a smart-case exact substring match against text.
---Convenience wrapper around smart_find for boolean checks.
---@param query string Search text
---@param text string Text to match against
---@return boolean
function M.is_smart_exact(query, text)
  return M.smart_find(query, text) ~= nil
end

---@class blink_md_refs.ParsedQuery
---@field file_query string Text before the `#` (or the full query if no `#`)
---@field heading_query? string Text after the `#`, or nil if no `#` present
---@field has_hash boolean Whether the query contains a `#` separator

---Parse a raw query string into file and heading components.
---Splits on the first `#` if present: "foo#bar" -> file_query="foo", heading_query="bar".
---@param raw string The raw query text after the `@` trigger
---@return blink_md_refs.ParsedQuery
function M.parse_query(raw)
  local hash_pos = raw:find("#", 1, true)
  if hash_pos then
    return {
      file_query = raw:sub(1, hash_pos - 1),
      heading_query = raw:sub(hash_pos + 1),
      has_hash = true,
    }
  end
  return { file_query = raw, heading_query = nil, has_hash = false }
end

---@class blink_md_refs.ParsedLine
---@field mode "none"|"normal"|"project_select"|"project_search"
---@field project? string Project name (only set in project_search mode)
---@field query string The query text relevant to the current mode

---Parse a line up to the cursor and determine the completion mode.
---Tries patterns in priority order: @!project@query, @!prefix, @query.
---@param line_before string Text from line start to cursor position
---@return blink_md_refs.ParsedLine
function M.parse_line(line_before)
  -- @!project@query — search within a named project
  local project, query = line_before:match("@!([%w_%-]+)@([^%s]*)$")
  if project then
    return { mode = "project_search", project = project, query = query }
  end
  -- @!prefix — selecting a project name
  local prefix = line_before:match("@!([%w_%-]*)$")
  if prefix then
    return { mode = "project_select", query = prefix }
  end
  -- @query — normal search in current project root
  local at_pos = line_before:match(".*()@")
  if at_pos then
    local q = line_before:sub(at_pos + 1)
    if not q:match("%s") then
      return { mode = "normal", query = q }
    end
  end
  return { mode = "none", query = "" }
end

---Compute a relative path from a directory to a target file.
---@param from_dir string Absolute directory path
---@param to_file string Absolute file path
---@return string relative The relative path (may include `../` segments)
function M.relative_path(from_dir, to_file)
  -- Normalize: ensure from_dir ends with / and remove trailing / from to_file
  from_dir = from_dir:gsub("/$", "") .. "/"
  to_file = to_file:gsub("/$", "")

  -- Find common prefix length (use string.byte to avoid per-char allocations)
  local i = 1
  local last_sep = 0
  local sep = 47 -- string.byte("/")
  while i <= #from_dir and i <= #to_file do
    local a, b = from_dir:byte(i), to_file:byte(i)
    if a ~= b then
      break
    end
    if a == sep then
      last_sep = i
    end
    i = i + 1
  end
  -- If we consumed all of from_dir and to_file[i] is "/" or we're past it
  if i > #from_dir then
    last_sep = #from_dir
  end

  -- Count remaining separators in from_dir after the common prefix
  local remaining = from_dir:sub(last_sep + 1)
  local ups = 0
  for _ in remaining:gmatch("/") do
    ups = ups + 1
  end

  local rel = to_file:sub(last_sep + 1)
  if rel:sub(1, 1) == "/" then
    rel = rel:sub(2)
  end

  if ups == 0 then
    return rel
  end
  return string.rep("../", ups) .. rel
end

return M
