---@class helpers.paths.Opts
---@field absolute? boolean   Use absolute path instead of project-relative.
---@field with_line? boolean  Append ":<row>" using the current window's cursor.
---@field dir_only? boolean   Yield only the parent directory of the file.
---@field basename? boolean   Yield only the filename (no directory).

local M = {}

---Project root for `buf` — git root via `vim.fs.root`, falling back to cwd.
---@param buf integer Buffer handle (0 for current).
---@return string root Absolute, normalized path.
function M.root(buf)
  local git = vim.fs.root(buf, { ".git" })
  return vim.fs.normalize(git or vim.uv.cwd())
end

---Path of `buf`'s file under `opts`, or nil when the buffer is unnamed.
---@param buf integer
---@param opts? helpers.paths.Opts
---@return string?
function M.path(buf, opts)
  opts = opts or {}
  local abs = vim.api.nvim_buf_get_name(buf)
  if abs == "" then
    return nil
  end
  abs = vim.fs.normalize(abs)

  local result
  if opts.basename then
    result = vim.fs.basename(abs)
  elseif opts.absolute then
    result = abs
  else
    local root = M.root(buf)
    if vim.startswith(abs, root .. "/") then
      result = abs:sub(#root + 2)
    else
      result = abs
    end
  end

  if opts.dir_only then
    result = vim.fs.dirname(result)
  end

  if opts.with_line then
    result = result .. ":" .. vim.api.nvim_win_get_cursor(0)[1]
  end

  return result
end

---Visible (non-floating) windows' buffers in the current tab, deduped, named only.
---@return integer[] bufs
function M.tab_window_buffers()
  local seen = {}
  local result = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      local buf = vim.api.nvim_win_get_buf(w)
      if vim.api.nvim_buf_get_name(buf) ~= "" and not seen[buf] then
        seen[buf] = true
        table.insert(result, buf)
      end
    end
  end
  return result
end

---Set the `+` register and notify. `content` may be a string or list of strings.
---@param content string|string[]|nil
---@param label string Short description used in the notification.
function M.copy(content, label)
  local text, count
  if type(content) == "table" then
    local filtered = {}
    for _, s in ipairs(content) do
      if s and s ~= "" then
        table.insert(filtered, s)
      end
    end
    text = table.concat(filtered, "\n")
    count = #filtered
  else
    text = content
    count = (content and content ~= "") and 1 or 0
  end

  if count == 0 then
    vim.notify("Nothing to copy", vim.log.levels.WARN)
    return
  end

  vim.fn.setreg("+", text)
  local suffix = count > 1 and (" (%d)"):format(count) or ""
  vim.notify(("Copied %s%s"):format(label, suffix))
end

return M
