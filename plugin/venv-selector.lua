-- github.com/linux-cultist/venv-selector.nvim
-- Auto-activates per-project venvs so Python LSPs can resolve imports.
-- PEP 723 script environments are handled in plugin/lsp/python.lua instead.
vim.pack.add({ "https://github.com/linux-cultist/venv-selector.nvim" }, { load = false })

local loaded = false
local function ensure_loaded()
  if loaded then
    return
  end
  loaded = true
  vim.cmd.packadd("venv-selector.nvim")
  require("venv-selector").setup({
    cache = { file = "~/.cache/venv-selector/venvs2.json" },
    hooks = {},
    search = {},
    options = {
      notify_user_on_venv_activation = true,
      cached_venv_automatic_activation = true,
      enable_default_searches = true,
      enable_cached_venvs = true,
      activate_venv_in_terminal = true,
      set_environment_variables = true,
      override_notify = true,
      search_timeout = 5,
      require_lsp_activation = true,
      picker_filter_type = "substring",
      selected_venv_marker_color = "#00FF00",
      selected_venv_marker_icon = "✔",
      picker_icons = {},
      picker_columns = { "marker", "search_icon", "search_name", "search_result" },
      picker = "auto",
      statusline_func = { nvchad = nil, lualine = nil },
      picker_options = {
        snacks = {
          layout = { preset = "select" },
        },
      },
    },
  })
end

-- Lazy-load venv-selector on the first Python buffer and register buffer-local
-- <localleader>v... keymaps. Scoping to the buffer keeps them out of non-Python
-- filetypes and ensures which-key only surfaces them where they apply. Fires on
-- every Python FileType so keymaps are wired to each buffer individually.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  desc = "Load venv-selector and register buffer-local Python venv keymaps",
  callback = function(ev)
    ensure_loaded()

    local bufnr = ev.buf
    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({
        { "<localleader>v", group = "venv", buffer = bufnr, icon = { icon = "󰌠", color = "green" } },
        { "<localleader>vs", "<Cmd>VenvSelect<CR>", buffer = bufnr, desc = "Select Virtualenv" },
        { "<localleader>vc", "<Cmd>VenvSelectCached<CR>", buffer = bufnr, desc = "Activate Cached Venv" },
        { "<localleader>vr", "<Cmd>VenvSelect<CR>", buffer = bufnr, desc = "Resync PEP 723 Script Deps" },
      })
    else
      local mappings_map = require("helpers.mappings").map
      local function map(lhs, rhs, desc)
        mappings_map(desc, "n", lhs, rhs, { buffer = bufnr, silent = true })
      end
      map("<localleader>vs", "<Cmd>VenvSelect<CR>", "Select Virtualenv")
      map("<localleader>vc", "<Cmd>VenvSelectCached<CR>", "Activate Cached Venv")
      map("<localleader>vr", "<Cmd>VenvSelect<CR>", "Resync PEP 723 Script Deps")
    end
  end,
})
