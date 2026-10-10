---The plugins the specs load and the type check reads, checked out under
---`.tests/deps` at the revisions `nvim-pack-lock.json` pins, so neither depends on
---what the editor happens to have installed. `nvim -l tests/support/deps.lua`
---installs them; `require("support.deps")` only locates them.
local this = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(this, ":p:h:h:h")

local M = {}

---@type string
M.dir = root .. "/.tests/deps"

---@type string[]
local plugins = {
  "blink.lib",
  "blink.pairs",
  "mini.extra",
  "mini.files",
  "mini.icons",
  "mini.input",
  "mini.pick",
  "mini.sessions",
  "mini.statusline",
  "plenary.nvim",
  "snacks.nvim",
  "which-key.nvim",
}

---No lockfile pins luacov, which is a library rather than a plugin. v0.17.0.
local luacov = { src = "https://github.com/lunarmodules/luacov", rev = "b1f9eae400da976b93edb7f94cf5d05f538a0655" }

---@class support.deps.Pin
---@field src string
---@field rev string

---Where the dependency `name` is checked out.
---@param name string
---@return string
function M.path(name)
  return M.dir .. "/" .. name
end

---The environment without GIT_* variables: a git hook exports GIT_DIR, which
---would point every command below at the repository being committed.
---@return table<string, string>
local function git_env()
  local env = vim.fn.environ()
  for name in pairs(env) do
    if name:match("^GIT_") then
      env[name] = nil
    end
  end
  return env
end

---Check each dependency out under `dir` at its pinned revision, fetching only the
---ones whose checkout is missing or elsewhere.
---@param pins table<string, support.deps.Pin> Keyed by directory name.
---@param dir string
---@return string[] errors One `name: reason` per dependency that failed.
function M.sync(pins, dir)
  local env = git_env()
  local jobs = {}
  for name, pin in pairs(pins) do
    local path = dir .. "/" .. name
    local head = vim.system({ "git", "-C", path, "rev-parse", "HEAD" }, { env = env, clear_env = true }):wait()
    if vim.trim(head.stdout or "") ~= pin.rev then
      vim.fn.mkdir(path, "p")
      local script = 'git init -q && git fetch -q --depth 1 "$1" "$2" && git checkout -q --detach FETCH_HEAD'
      jobs[name] = vim.system(
        { "sh", "-c", script, "sh", pin.src, pin.rev },
        { cwd = path, env = env, clear_env = true, text = true }
      )
    end
  end

  local errors = {}
  for name, job in pairs(jobs) do
    local result = job:wait()
    if result.code ~= 0 then
      table.insert(errors, name .. ": " .. vim.trim(result.stderr))
    end
  end
  return errors
end

---Sync every dependency to its pin, raising if any failed.
function M.install()
  local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/nvim-pack-lock.json"), "\n")).plugins
  local pins = { luacov = luacov }
  for _, name in ipairs(plugins) do
    pins[name] = { src = lock[name].src, rev = lock[name].rev }
  end
  local errors = M.sync(pins, M.dir)
  if #errors > 0 then
    error(table.concat(errors, "\n"), 0)
  end
end

if arg and arg[0] and vim.fn.fnamemodify(arg[0], ":p") == vim.fn.fnamemodify(this, ":p") then
  M.install()
end

return M
