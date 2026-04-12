--- Asynchronous plugin update checker for vim.pack.
---
--- Compares locked revisions in nvim-pack-lock.json against remote HEAD
--- using `git ls-remote`. All network calls run in libuv's thread pool
--- via `vim.system()` — zero impact on the main loop.
---
--- Results are cached to disk for 24 hours. The cache is invalidated
--- when the lock file is modified (e.g. after `vim.pack.update()`),
--- triggering a fresh check on next startup.
---
--- Usage:
---   require("config.pack-updates").check()  -- kick off async check (respects cache)
---   require("config.pack-updates").update_count()  -- 0 until check completes
---   require("config.pack-updates").is_checking()   -- true while in progress
---   require("config.pack-updates").spinner_frame()  -- current spinner char or nil

local M = {}

local MAX_CONCURRENT = 10 -- max parallel git ls-remote processes
local CACHE_TTL = 86400 -- 24 hours in seconds
local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local SPINNER_INTERVAL_MS = 80
local LOCKFILE_PATH = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
local CACHE_PATH = vim.fn.stdpath("cache") .. "/pack-updates-cache.json"

---@type integer Number of plugins with a newer remote HEAD than the locked rev
local count = 0

---@type integer Current spinner frame index (1-based)
local spinner_idx = 1

---@type uv.uv_timer_t? Active spinner timer handle
local spinner_timer = nil

---@class PackUpdateCache
---@field checked_at integer Unix timestamp of last check
---@field count integer Number of outdated plugins at last check

---@return table<string, { src: string, rev: string }>
local function read_lockfile()
  local f = io.open(LOCKFILE_PATH, "r")
  if not f then
    return {}
  end
  local data = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, data)
  if not ok or not decoded or not decoded.plugins then
    return {}
  end
  return decoded.plugins
end

---@return PackUpdateCache?
local function read_cache()
  local f = io.open(CACHE_PATH, "r")
  if not f then
    return nil
  end
  local data = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, data)
  if not ok then
    return nil
  end
  return decoded
end

---@param update_count integer
local function write_cache(update_count)
  ---@type PackUpdateCache
  local cache = { checked_at = os.time(), count = update_count }
  local f = io.open(CACHE_PATH, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(cache))
  f:close()
end

--- Check whether the cache is still valid. The cache is valid when:
--- 1. It exists and can be decoded
--- 2. It was written less than 24 hours ago
--- 3. The lock file hasn't been modified since the cache was written
---@return boolean valid
---@return PackUpdateCache? cache The cached data if valid
local function cache_is_valid()
  local cache = read_cache()
  if not cache then
    return false, nil
  end

  if (os.time() - cache.checked_at) >= CACHE_TTL then
    return false, nil
  end

  local stat = vim.uv.fs_stat(LOCKFILE_PATH)
  if stat and stat.mtime.sec > cache.checked_at then
    return false, nil
  end

  return true, cache
end

-- Start the braille spinner animation in the statusline.
-- Cycles through SPINNER_FRAMES on a repeating timer, redrawing
-- the statusline on each tick. spinner_timer doubles as the
-- "is checking" flag — nil means idle.
local function start_spinner()
  if spinner_timer then
    return
  end
  spinner_idx = 1
  spinner_timer = vim.uv.new_timer()
  spinner_timer:start(
    0,
    SPINNER_INTERVAL_MS,
    vim.schedule_wrap(function()
      spinner_idx = (spinner_idx % #SPINNER_FRAMES) + 1
      vim.cmd.redrawstatus()
    end)
  )
end

local function stop_spinner()
  if not spinner_timer then
    return
  end
  spinner_timer:stop()
  spinner_timer:close()
  spinner_timer = nil
end

--- Return the current spinner frame character, or nil if not spinning.
---@return string?
function M.spinner_frame()
  if not spinner_timer then
    return nil
  end
  return SPINNER_FRAMES[spinner_idx]
end

--- Compare locked revisions against remote HEAD for all plugins.
--- Respects the 24-hour cache — skips network calls if a recent
--- check result is available and the lock file hasn't changed.
--- Runs `git ls-remote` asynchronously, batched to at most MAX_CONCURRENT
--- concurrent processes. Triggers a statusline redraw on completion.
function M.check()
  local valid, cache = cache_is_valid()
  if valid and cache then
    count = cache.count
    vim.cmd.redrawstatus()
    return
  end

  local plugins = read_lockfile()
  if vim.tbl_isempty(plugins) then
    return
  end

  count = 0
  start_spinner()

  ---@type { src: string, rev: string }[]
  local queue = {}
  for _, spec in pairs(plugins) do
    table.insert(queue, { src = spec.src, rev = spec.rev })
  end

  local total = #queue
  local completed = 0
  local idx = 0

  -- Pull the next plugin off the queue and check it. Each completion
  -- callback spawns the next check, keeping MAX_CONCURRENT in flight.
  local function spawn_next()
    idx = idx + 1
    if idx > total then
      return
    end

    local entry = queue[idx]
    vim.system({ "git", "ls-remote", entry.src, "HEAD" }, {}, function(result)
      vim.schedule(function()
        if result.code == 0 and result.stdout then
          local remote_rev = result.stdout:match("^(%x+)")
          if remote_rev and remote_rev ~= entry.rev then
            count = count + 1
          end
        end

        completed = completed + 1
        if completed == total then
          stop_spinner()
          write_cache(count)
          vim.cmd.redrawstatus()
        else
          spawn_next()
        end
      end)
    end)
  end

  for _ = 1, math.min(MAX_CONCURRENT, total) do
    spawn_next()
  end
end

--- Return the number of plugins with available updates.
---@return integer
function M.update_count()
  return count
end

--- Return whether a check is currently in progress.
---@return boolean
function M.is_checking()
  return spinner_timer ~= nil
end

return M
