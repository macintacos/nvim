local M = {}

---@type table<string, string[]>
local cache = {}

---Asynchronously list project files via `rg`. The default lister; replaceable in tests.
---@param root string
---@param cb fun(paths: string[])
local function default_lister(root, cb)
  vim.system(
    { "rg", "--files", "--hidden", "--glob", "!.git" },
    { cwd = root, text = true },
    vim.schedule_wrap(function(res)
      local out = {}
      if res.code == 0 and res.stdout then
        for line in res.stdout:gmatch("[^\n]+") do
          out[#out + 1] = line
        end
      end
      cb(out)
    end)
  )
end

---@type fun(root: string, cb: fun(paths: string[]))
local lister = default_lister

---Walk up from `start_path` looking for a `.git` directory; falls back to cwd.
---@param start_path string|nil
---@return string
function M.root(start_path)
  local dir = start_path or vim.fn.getcwd()
  if vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.fnamemodify(dir, ":h")
  end

  while dir ~= "" do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then
      return dir
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return vim.fn.getcwd()
end

---Asynchronously list files under `root`, calling `cb` with the list.
---Subsequent calls for the same root return the cached list.
---@param root string
---@param cb fun(paths: string[])
function M.list(root, cb)
  if cache[root] then
    cb(cache[root])
    return
  end
  lister(root, function(paths)
    -- Only cache non-empty results; an empty list is usually an rg failure
    -- (binary missing, no permission) and should be retried next time.
    if #paths > 0 then
      cache[root] = paths
    end
    cb(paths)
  end)
end

---Invalidate the cache for a specific root (or all roots if nil).
---@param root string|nil
function M.invalidate(root)
  if root then
    cache[root] = nil
  else
    cache = {}
  end
end

---Test hook: replace the lister with a custom function.
---@param fn fun(root: string, cb: fun(paths: string[]))
function M._set_lister(fn)
  lister = fn
end

---Test hook: restore default state.
function M._reset()
  cache = {}
  lister = default_lister
end

return M
