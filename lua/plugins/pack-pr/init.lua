local registry = require("plugins.pack-pr.registry")

local M = {}

---@type pack-pr.Repo[]
local repos = {}

---@class pack-pr.Config
---@field repos? (string|table)[] Managed repos: bare "owner/repo" strings or override tables.

---Configure the managed-repo registry and register the `:PackPR` command.
---@param opts pack-pr.Config?
function M.setup(opts)
  opts = opts or {}
  repos = registry.build(opts.repos or registry.DEFAULT)
  vim.api.nvim_create_user_command("PackPR", function()
    require("plugins.pack-pr.picker").open(repos)
  end, { desc = "Pick a PR branch to track via vim.pack" })
end

---The normalized managed-repo registry (populated by setup()).
---@return pack-pr.Repo[]
function M.registry()
  return repos
end

return M
