---Which part of a change a file belongs to, read off its path alone.

local M = {}

---@alias changeset.SectionKey "implementation"|"tests"|"docs"|"config"

---@class changeset.Section
---@field key changeset.SectionKey
---@field label string
---@field icon string Directory name `MiniIcons.get("directory", …)` draws the header's icon for.

---@type changeset.Section[] Display order.
M.ORDER = {
  { key = "implementation", label = "Implementation", icon = "src" },
  { key = "tests", label = "Tests", icon = "tests" },
  { key = "docs", label = "Docs", icon = "docs" },
  { key = "config", label = "Config", icon = ".config" },
}

---@param globs string[]
---@return vim.lpeg.Pattern
local function any_glob(globs)
  local pattern = vim.glob.to_lpeg(globs[1])
  for i = 2, #globs do
    pattern = pattern + vim.glob.to_lpeg(globs[i])
  end
  return pattern
end

local TEST_DIRS = { tests = true, test = true, spec = true, __tests__ = true, testdata = true }
local TEST_FILES = any_glob({ "*_spec.*", "*_test.*", "*.test.*", "*.spec.*", "test_*.py", "conftest.py", "*.bats" })
local DOC_FILES = any_glob({ "*.md", "*.mdx", "*.rst", "README*", "CHANGELOG*" })
local DOC_DIRS = { doc = true, docs = true }
local CONFIG_FILES = any_glob({ "*.toml", "*.yaml", "*.yml", "*.pkl", "*.json", "*.ini", "*.cfg", ".*" })
local CONFIG_NAMES = { Makefile = true, Dockerfile = true, ["go.mod"] = true }
local SCRIPT_FILES = any_glob({ "*.sh", "*.bash", "*.py", "*.js", "*.ts", "*.rs", "*.go", "*.lua" })

---@param dirs string[]
---@param set table<string, true>
---@return boolean
local function has_dir(dirs, set)
  return vim.iter(dirs):any(function(d)
    return set[d] ~= nil
  end)
end

---@param path string Repo-relative, `/`-separated.
---@return changeset.SectionKey
function M.classify(path)
  local dirs = vim.split(path, "/", { plain = true })
  local name = table.remove(dirs)
  if has_dir(dirs, TEST_DIRS) or TEST_FILES:match(name) then
    return "tests"
  end
  if DOC_FILES:match(name) or (vim.endswith(name, ".txt") and has_dir(dirs, DOC_DIRS)) then
    return "docs"
  end
  if
    CONFIG_FILES:match(name)
    or CONFIG_NAMES[name]
    or (vim.list_contains(dirs, ".github") and not SCRIPT_FILES:match(name))
  then
    return "config"
  end
  return "implementation"
end

return M
