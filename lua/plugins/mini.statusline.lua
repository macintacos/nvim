-- github.com/nvim-mini/mini.statusline
-- Status line

-- Show lazy.nvim updates in statusline for 5 seconds once detected
local show_lazy_updates = true
local lazy_updates_timer_started = false

---@module "lazy"
---@type LazySpec
return {
  "nvim-mini/mini.statusline",
  version = "*",
  opts = {
    content = {
      active = function()
        local MiniStatusline = require("mini.statusline")

        -- Standard sections
        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
        local git = MiniStatusline.section_git({ trunc_width = 40 })
        local diff = MiniStatusline.section_diff({ trunc_width = 75 })
        local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
        local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
        local filename = MiniStatusline.section_filename({ trunc_width = 140 })
        local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
        local location = MiniStatusline.section_location({ trunc_width = 75 })
        local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

        -- Lazy updates section (only shown for 5 seconds once updates are detected)
        local lazy_updates = ""
        if show_lazy_updates then
          local lazy_status = require("lazy.status")
          if lazy_status.has_updates() then
            lazy_updates = " " .. lazy_status.updates() .. " plugin updates found"
            -- Start the 5-second timer only once, when updates are first detected
            if not lazy_updates_timer_started then
              lazy_updates_timer_started = true
              vim.defer_fn(function()
                show_lazy_updates = false
                vim.cmd("redrawstatus")
              end, 5000)
            end
          end
        end

        return MiniStatusline.combine_groups({
          { hl = mode_hl, strings = { mode } },
          { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
          "%<", -- Mark general truncate point
          { hl = "MiniStatuslineFilename", strings = { filename } },
          "%=", -- End left alignment
          { hl = "MiniStatuslineFileinfo", strings = { lazy_updates, fileinfo } },
          { hl = mode_hl, strings = { search, location } },
        })
      end,
    },
  },
}
