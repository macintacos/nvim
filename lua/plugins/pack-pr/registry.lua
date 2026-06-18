local M = {}

---Default managed repos. Each entry is a bare "owner/repo" string (or a table
---that overrides a derived field). Onboarding a repo is a one-line addition.
---@type (string|table)[]
M.DEFAULT = { "macintacos/agentcomplete.nvim" }

---@class pack-pr.Repo
---@field repo string The "owner/repo" gh query target.
---@field src string The `vim.pack` source URL.
---@field name string The `vim.pack` plugin name (passed to `vim.pack.update`).
---@field spec_file string The config-relative path of the spec file to rewrite.

---Normalize a registry entry into a full `pack-pr.Repo`. An entry is either a
---bare "owner/repo" string or a table overriding any derived field. `src`,
---`name`, and `spec_file` are derived from `repo` when omitted, so the minimal
---entry is just the "owner/repo" string.
---@param entry string|table
---@return pack-pr.Repo
function M.normalize(entry)
  if type(entry) == "string" then
    entry = { repo = entry }
  end
  local repo = assert(entry.repo, "pack-pr: registry entry needs a `repo` field")
  local src = entry.src or ("https://github.com/" .. repo)
  local name = entry.name or src:match("([^/]+)$")
  local spec_file = entry.spec_file or ("plugin/" .. name:gsub("%.n?vim$", "") .. ".lua")
  return { repo = repo, src = src, name = name, spec_file = spec_file }
end

---Normalize a list of registry entries.
---@param entries (string|table)[]
---@return pack-pr.Repo[]
function M.build(entries)
  local repos = {}
  for _, entry in ipairs(entries) do
    repos[#repos + 1] = M.normalize(entry)
  end
  return repos
end

return M
