local registry = require("plugins.pack-pr.registry")

local M = {}

---@type string
local owner

---@class pack-pr.Config
---@field owner string GitHub owner whose installed vim.pack plugins are managed.

---Store the plugin owner and register the `:PackPR` command.
---@param opts pack-pr.Config
function M.setup(opts)
  owner = opts.owner
  vim.api.nvim_create_user_command("PackPR", function()
    require("plugins.pack-pr.picker").open(M.registry())
  end, { desc = "Pick a plugin PR, install its branch and restart into it" })
end

---The owner's installed vim.pack plugins, discovered afresh on each call.
---@return pack-pr.Repo[]
function M.registry()
  return registry.discover(vim.pack.get(nil, { info = false }), owner)
end

return M
