-- github.com/nvim-mini/mini.files
-- Interactive column-view file explorer

local augroup = vim.api.nvim_create_augroup('mini_files_config', { clear = true })

---@return integer
local function preview_width()
  return math.floor(vim.o.columns * 0.5)
end

--- Compute the display width of a directory buffer's longest visible entry.
--- Directory lines use the format `/<path_id>/<icon>/<name>`, where the
--- path_id and separators are concealed. Returns only the icon+name width.
--- Returns nil if the buffer is not a directory listing.
---@param buf_id integer
---@return integer?
local function directory_content_width(buf_id)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local max_width, found = 0, false
  for _, line in ipairs(lines) do
    local icon, name = line:match('^/%d+/(.-)/(.*)')
    if icon then
      found = true
      local w = vim.fn.strdisplaywidth(icon) + vim.fn.strdisplaywidth(name)
      if w > max_width then max_width = w end
    end
  end
  return found and max_width or nil
end

-- Resize preview pane when terminal dimensions change
vim.api.nvim_create_autocmd('VimResized', {
  group = augroup,
  callback = function()
    local ok, files = pcall(require, 'mini.files')
    if not ok then return end
    local width = preview_width()
    files.config.windows.width_preview = width
    pcall(files.refresh, { windows = { width_preview = width } })
  end,
})

-- Cap window height at 70% of screen; fit directory preview width to content
vim.api.nvim_create_autocmd('User', {
  group = augroup,
  pattern = 'MiniFilesWindowUpdate',
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

    local files = require('mini.files')
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

-- Buffer-local keymaps for the file explorer
vim.api.nvim_create_autocmd('User', {
  group = augroup,
  pattern = 'MiniFilesBufferCreate',
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    local buf = args.data.buf_id
    local files = require('mini.files')

    vim.keymap.set('n', '<CR>', function()
      files.go_in({ close_on_file = true })
    end, { buffer = buf, desc = 'Open file or expand directory' })

    vim.keymap.set('n', 'H', function()
      files.open(vim.uv.cwd(), false)
    end, { buffer = buf, desc = 'Go to cwd root' })

    vim.keymap.set('n', 'q', function()
      files.synchronize()
      files.close()
    end, { buffer = buf, desc = 'Sync and close' })
  end,
})

---@module "lazy"
---@type LazySpec
return {
  "nvim-mini/mini.files",
  version = "*",
  opts = function()
    return {
      windows = {
        preview = true,
        width_preview = preview_width(),
      },
      options = {
        use_as_default_explorer = true,
      },
    }
  end
}
