---Customised entries for `MiniPick.registry`.
---
---Each submodule is required on first use rather than at startup, so opening
---`:Pick files` never loads the LSP or git picker code.

local M = {}

---Register the customised pickers. Must run after `mini.pick` and `mini.extra`
---have been set up, since it writes into the registry they create.
function M.setup()
  MiniPick.registry.files = function()
    return require("plugins.mini-pickers.files").pick()
  end

  MiniPick.registry.grep_live = function(local_opts)
    return require("plugins.mini-pickers.grep").pick(local_opts)
  end

  MiniPick.registry.lsp = function(local_opts)
    local_opts = local_opts or {}
    local scope = tostring(local_opts.scope or "")
    if scope == "document_symbol" then
      return require("plugins.mini-pickers.outline").pick(local_opts)
    end
    -- references/definition/etc. are location lists, not symbols — leave them be.
    if not scope:find("symbol") then
      return MiniExtra.pickers.lsp(local_opts)
    end
    return require("plugins.mini-pickers.workspace").pick(local_opts, scope)
  end

  MiniPick.registry.git_blame_line = function()
    return require("plugins.mini-pickers.git").blame_line()
  end
end

return M
