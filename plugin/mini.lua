-- mini.nvim modules: statusline, icons, cursorword, hipatterns, trailspace, files
vim.pack.add({
  { src = "https://github.com/nvim-mini/mini.statusline", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.icons", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.cursorword", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.hipatterns", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.trailspace", version = "stable" },
  { src = "https://github.com/nvim-mini/mini.files", version = "stable" },
})

-- ============================================================================
-- mini.statusline
-- ============================================================================

-- Override default section backgrounds to match the dark theme
local function set_statusline_highlights()
  vim.api.nvim_set_hl(0, "MiniStatuslineDevinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslineFileinfo", { bg = "#1a1a2e" })
  vim.api.nvim_set_hl(0, "MiniStatuslinePackUpdates", { fg = "#a6e3a1", bg = "#1a1a2e" })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })
set_statusline_highlights()

local pack_updates = require("config.pack-updates")

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

require("mini.statusline").setup({
  content = {
    active = function()
      local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
      local git = MiniStatusline.section_git({ trunc_width = 40 })
      local diff = MiniStatusline.section_diff({ trunc_width = 75 })
      local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
      local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
      local filename = MiniStatusline.section_filename({ trunc_width = 140 })
      local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
      local location = MiniStatusline.section_location({ trunc_width = 75 })
      local search = MiniStatusline.section_searchcount({ trunc_width = 75 })
      local updates = section_pack_updates({ trunc_width = 75 })

      return MiniStatusline.combine_groups({
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
        "%<",
        { hl = "MiniStatuslineFilename", strings = { filename } },
        "%=",
        { hl = "MiniStatuslinePackUpdates", strings = { updates } },
        { hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
        { hl = mode_hl, strings = { search, location } },
      })
    end,
  },
})

-- ============================================================================
-- mini.files
-- ============================================================================

-- Half the screen width, used for the preview pane
local function preview_width()
  return math.floor(vim.o.columns * 0.5)
end

-- Measures the widest entry in a directory listing buffer so we can
-- auto-fit the preview column to its content instead of a fixed width.
-- Directory lines follow the format /<path_id>/<icon>/<name> where
-- the path_id and separators are concealed — we only measure icon+name.
-- Returns nil when the buffer isn't a directory listing.
---@param buf_id integer
---@return integer?
local function directory_content_width(buf_id)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local max_width, found = 0, false
  for _, line in ipairs(lines) do
    local icon, name = line:match("^/%d+/(.-)/(.*)")
    if icon then
      found = true
      local w = vim.fn.strdisplaywidth(icon) + vim.fn.strdisplaywidth(name)
      if w > max_width then
        max_width = w
      end
    end
  end
  return found and max_width or nil
end

---@type string?
local cut_line = nil

local augroup = vim.api.nvim_create_augroup("mini_files_config", { clear = true })

-- Keep the preview pane width proportional when the terminal is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup,
  callback = function()
    local ok, files = pcall(require, "mini.files")
    if not ok then
      return
    end
    local width = preview_width()
    files.config.windows.width_preview = width
    pcall(files.refresh, { windows = { width_preview = width } })
  end,
})

-- Cap window height at 70% of screen and auto-fit directory preview
-- columns to their content width instead of using the full preview width
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesWindowUpdate",
  ---@param args { data: { win_id: integer, buf_id: integer } }
  callback = function(args)
    local win_id = args.data.win_id
    local buf_id = args.data.buf_id
    local config = vim.api.nvim_win_get_config(win_id)
    local changed = false

    local max_height = math.floor(vim.o.lines * 0.7)
    if config.height > max_height then
      config.height = max_height
      changed = true
    end

    local files = require("mini.files")
    if config.width == files.config.windows.width_preview then
      local content_width = directory_content_width(buf_id)
      if content_width then
        config.width = content_width + 1
        changed = true
      end
    end

    if changed then
      vim.api.nvim_win_set_config(win_id, config)
    end
  end,
})

-- Disable scrolloff inside mini.files windows so entries at the top
-- and bottom of the list aren't pushed away from the edge
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "minifiles",
  callback = function()
    vim.opt_local.scrolloff = 0
  end,
})

-- Buffer-local keymaps set each time a new explorer buffer is created
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesBufferCreate",
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    local buf = args.data.buf_id
    local files = require("mini.files")

    -- <CR>: open the file under the cursor (closing the explorer) or
    -- expand a directory in a new column. If the cursor is on a freshly
    -- typed line that doesn't exist on disk yet, synchronize first so
    -- mini.files creates the entry, then open it.
    vim.keymap.set("n", "<CR>", function()
      local entry = files.get_fs_entry()
      if entry then
        files.go_in({ close_on_file = true })
      else
        files.synchronize()
        files.go_in({ close_on_file = true })
      end
    end, { buffer = buf, desc = "Open file or expand directory" })

    -- Route :w through BufWriteCmd. mini.files creates scratch buffers
    -- (buftype=nofile) which would otherwise reject :w with E382.
    vim.bo[buf].buftype = "acwrite"

    -- Intercept :w to trigger synchronize instead of a regular file write —
    -- prompts the user to confirm pending file system changes
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      callback = function()
        files.synchronize()
      end,
    })

    -- :q (and therefore :wq, :x) closes the whole explorer, matching
    -- the q / <Esc> keymap behavior. Scheduled so the original :q
    -- finishes first, then files.close() cleans up the rest.
    vim.api.nvim_create_autocmd("QuitPre", {
      buffer = buf,
      callback = function()
        vim.schedule(function()
          pcall(files.close)
        end)
      end,
    })

    -- <C-s>: synchronize pending filesystem changes with a confirm prompt.
    -- Overrides the global <C-s> mapping for this buffer because the global
    -- one uses <cmd>w<cr>, which runs :w in a restricted context where
    -- vim.fn.confirm returns its default (Yes) without prompting — silently
    -- auto-applying changes. Feeding <Esc> afterwards exits insert/visual
    -- mode so the keymap behaves consistently across modes.
    vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", function()
      files.synchronize()
      local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
      vim.api.nvim_feedkeys(esc, "n", false)
    end, { buffer = buf, desc = "Synchronize mini.files" })

    -- H: jump the explorer back to the current working directory.
    -- Useful when nested deep in a tree and you want to start over from
    -- the project root without closing and reopening the explorer.
    vim.keymap.set("n", "H", function()
      files.open(vim.uv.cwd(), false)
    end, { buffer = buf, desc = "Go to cwd root" })

    -- q / <Esc>: close the explorer, synchronizing first so any pending
    -- edits are not silently dropped — the confirm prompt still runs.
    local function sync_and_close()
      files.synchronize()
      files.close()
    end

    vim.keymap.set("n", "q", sync_and_close, { buffer = buf, desc = "Sync and close" })
    vim.keymap.set("n", "<Esc>", sync_and_close, { buffer = buf, desc = "Sync and close" })

    -- mm: cut the entry under the cursor. Stashes the entire buffer line
    -- (including the concealed /<path_id>/ prefix) in a module-local
    -- variable and removes it from the buffer. Preserving the path_id is
    -- what lets a subsequent paste be recognized by mini.files's diff as
    -- a move rather than a delete + create.
    vim.keymap.set("n", "mm", function()
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      local line = vim.api.nvim_buf_get_lines(buf, lnum - 1, lnum, false)[1]
      if not line or line == "" then
        return
      end
      cut_line = line
      vim.api.nvim_buf_set_lines(buf, lnum - 1, lnum, false, {})
    end, { buffer = buf, desc = "Cut entry (paste with p)" })

    -- p: paste the previously cut entry below the cursor in any mini.files
    -- buffer. The move is not committed until the user synchronizes
    -- (:w / <C-s> / q), so this is safe to undo by closing without sync.
    vim.keymap.set("n", "p", function()
      if not cut_line then
        vim.notify("mini.files: nothing to paste", vim.log.levels.WARN)
        return
      end
      local lnum = vim.api.nvim_win_get_cursor(0)[1]
      vim.api.nvim_buf_set_lines(buf, lnum, lnum, false, { cut_line })
      cut_line = nil
    end, { buffer = buf, desc = "Paste cut entry" })

    -- <M-p>: toggle the preview pane on/off. Flipping the config flag
    -- alone doesn't redraw, so we re-set the current branch to force
    -- mini.files to rebuild the layout with the new preview setting.
    vim.keymap.set("n", "<M-p>", function()
      files.config.windows.preview = not files.config.windows.preview
      local state = files.get_explorer_state()
      if state then
        local branch = vim.list_slice(state.branch, 1, state.depth_focus)
        files.set_branch(branch, { depth_focus = state.depth_focus })
      end
    end, { buffer = buf, desc = "Toggle preview pane" })
  end,
})

require("mini.files").setup({
  windows = {
    preview = true,
    width_preview = preview_width(),
  },
  options = {
    use_as_default_explorer = true,
  },
})
