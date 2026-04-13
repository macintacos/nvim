local M = {}

---@type table<number, string>
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
---@param bufnr? number
---@return string
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
---@param text string
---@return string
function M.heading_to_anchor(text)
  return text:lower():gsub("[^%w%s%-_]", ""):gsub("%s+", "-"):gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
end

---Left-truncate a string to max_len display columns, prepending "…" if truncated.
---The ellipsis counts as 1 display column.
---@param text string
---@param max_len number Display width limit
---@return string
function M.truncate_left(text, max_len)
  if #text <= max_len then
    return text
  end
  -- "…" is 1 display column, so keep max_len - 1 ASCII chars from the right
  return "…" .. text:sub(-(max_len - 1))
end

---Smart-case plain-text search: case-insensitive when query is all lowercase,
---case-sensitive otherwise. Returns the 1-based start position, or nil.
---@param query string
---@param text string
---@return number? start 1-based byte position of the match
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
---@param query string
---@param text string
---@return boolean
function M.is_smart_exact(query, text)
  return M.smart_find(query, text) ~= nil
end

---Parse a raw query string into file and heading components.
---Splits on the first `#` if present: "foo#bar" -> file_query="foo", heading_query="bar".
---@param raw string
---@return { file_query: string, heading_query: string?, has_hash: boolean }
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

---Compute a relative path from a directory to a target file.
---@param from_dir string Absolute directory path
---@param to_file string Absolute file path
---@return string
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
