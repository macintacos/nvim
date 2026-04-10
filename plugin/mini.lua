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
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_highlights })
set_statusline_highlights()
require("mini.statusline").setup()

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

-- Buffer-local keymaps set each time a new explorer buffer is created
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "MiniFilesBufferCreate",
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    local buf = args.data.buf_id
    local files = require("mini.files")

    vim.keymap.set("n", "<CR>", function()
      local entry = files.get_fs_entry()
      if entry then
        files.go_in({ close_on_file = true })
      else
        -- Entry doesn't exist yet — sync to create it, then open
        files.synchronize()
        files.go_in({ close_on_file = true })
      end
    end, { buffer = buf, desc = "Open file or expand directory" })

    -- Intercept :w to trigger synchronize instead of a regular file write —
    -- prompts the user to confirm pending file system changes
    vim.api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      callback = function()
        files.synchronize()
      end,
    })

    vim.keymap.set("n", "H", function()
      files.open(vim.uv.cwd(), false)
    end, { buffer = buf, desc = "Go to cwd root" })

    local function sync_and_close()
      files.synchronize()
      files.close()
    end

    vim.keymap.set("n", "q", sync_and_close, { buffer = buf, desc = "Sync and close" })
    vim.keymap.set("n", "<Esc>", sync_and_close, { buffer = buf, desc = "Sync and close" })

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
