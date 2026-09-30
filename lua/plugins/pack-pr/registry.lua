local M = {}

---@class pack-pr.Repo
---@field repo string The "owner/repo" gh query target.
---@field src string The `vim.pack` source URL.
---@field name string The `vim.pack` plugin name (passed to `vim.pack.update`).
---@field spec_file string The config-relative path of the spec file to rewrite.
---@field path string The plugin's install directory.

---Build a `pack-pr.Repo` for each active plugin hosted under `owner` on GitHub.
---@param plugins vim.pack.PlugData[]
---@param owner string
---@return pack-pr.Repo[]
function M.discover(plugins, owner)
  local prefix = "https://github.com/" .. owner .. "/"
  local repos = {}
  for _, p in ipairs(plugins) do
    local src, name = p.spec.src, p.spec.name
    if p.active and vim.startswith(src, prefix) then
      repos[#repos + 1] = {
        repo = src:sub(#"https://github.com/" + 1),
        src = src,
        name = name,
        spec_file = "plugin/" .. name:gsub("%.n?vim$", "") .. ".lua",
        path = p.path,
      }
    end
  end
  return repos
end

return M
