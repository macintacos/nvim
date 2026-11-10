-- github.com/nvim-mini/mini.statusline
-- Builds 'statusline' out of mode, git, diagnostic, filename, and location sections.
-- Docs: https://github.com/nvim-mini/mini.statusline/blob/main/doc/mini-statusline.txt
vim.pack.add({ { src = "https://github.com/nvim-mini/mini.statusline", version = "stable" } })

local pack_updates = require("plugins.pack-updates")

-- Override default section backgrounds so the line sits just off the terminal
-- background and only the mode sections carry color. The mode sections are the
-- colorscheme's.
local function set_statusline_highlights()
  local p = require("helpers.palette").active()
  if not p then
    return
  end
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = p.bg0 })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = p.bg0 })
  vim.api.nvim_set_hl(0, "MiniStatuslinePackUpdates", { fg = p.green.base, bg = p.bg0 })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })

-- Custom statusline section: shows a braille spinner while checking
-- for plugin updates, then icon + count when updates are available.
---@param args { trunc_width: integer }
---@return string
local function section_pack_updates(args)
  if MiniStatusline.is_truncated(args.trunc_width) then
    return ""
  end
  local frame = pack_updates.spinner_frame()
  if frame then
    return frame
  end
  local n = pack_updates.update_count()
  if n > 0 then
    return " " .. n
  end
  return ""
end

---The current file's path from its repo root, or mini's own filename section outside a repo.
---@param args { trunc_width: integer }
---@return string
local function section_filename(args)
  local root = vim.bo.buftype == "" and vim.fs.root(0, ".git")
  local name = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  if not root or not vim.startswith(name, root .. "/") then
    return MiniStatusline.section_filename(args)
  end
  return name:sub(#root + 2):gsub("%%", "%%%%") .. "%m%r"
end

---One statusline of `left`, `middle`, and `right`, with `middle` centered in `columns`
---cells, or hard against `left` when `left` reaches past where it would start.
---@param left string
---@param middle string
---@param right string
---@param columns integer
---@return string
local function centered(left, middle, right, columns)
  local function width(item)
    return vim.api.nvim_eval_statusline(item, {}).width
  end
  local pad = math.floor((columns - width(middle)) / 2) - width(left)
  return left .. (" "):rep(math.max(pad, 0)) .. middle .. "%=" .. right
end

require("mini.statusline").setup({
  content = {
    active = function()
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local git = MiniStatusline.section_git({ trunc_width = 40 })
      local diff = MiniStatusline.section_diff({ trunc_width = 75 })
      local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
      local filename = section_filename({ trunc_width = 140 })
      local location = MiniStatusline.section_location({ trunc_width = 75 })
      local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
      local updates = section_pack_updates({ trunc_width = 75 })

      local left = MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        { hl = "MiniStatuslineFilename" },
      })
      local middle = MiniStatusline.combine_groups({ "%<", { strings = { filename } } })
      local right = MiniStatusline.combine_groups({
        { hl = "MiniStatuslinePackUpdates", strings = { updates } },
        { hl = mode_hl, strings = { search, location } },
      })
      return centered(left, middle, right, vim.o.columns)
    end,
  },
})

-- Redraws the statusline when gitsigns reports a new branch or diff count. It
-- updates those from a git watcher, so a branch switched outside a keypress,
-- such as from the branch picker or lazygit, would otherwise show stale until
-- the next one. Fires on gitsigns' `User GitSignsUpdate`.
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("StatuslineGitsigns", { clear = true }),
  pattern = "GitSignsUpdate",
  desc = "Redraw the statusline when gitsigns' status changes",
  command = "redrawstatus",
})
