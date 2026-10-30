---Hover, definition, and references for a Svelte project's own CSS classes, scoped
---the way Svelte scopes component styles.

local M = {}

---Register the in-process `svelte_css` server for components and stylesheets.
---@param _opts? table
function M.setup(_opts)
  vim.lsp.config("svelte_css", {
    cmd = function(dispatchers, config)
      -- workspace_required keeps the server off any buffer without a root.
      return require("plugins.svelte-css.server").start(dispatchers, config.root_dir --[[@as string]])
    end,
    filetypes = { "svelte", "css" },
    -- Nested, so all rank equal and the nearest wins.
    root_markers = { { "svelte.config.js", "svelte.config.mjs", "svelte.config.ts" } },
    workspace_required = true,
  })
  vim.lsp.enable("svelte_css")
end

return M
