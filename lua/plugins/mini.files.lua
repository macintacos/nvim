-- github.com/nvim-mini/mini.files
-- Interactive column-view file explorer

---@return integer
local function preview_width()
  return math.floor(vim.o.columns * 0.5)
end

-- Resize preview pane when terminal dimensions change
vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    local ok, files = pcall(require, 'mini.files')
    if not ok then return end
    local width = preview_width()
    files.config.windows.width_preview = width
    pcall(files.refresh, { windows = { width_preview = width } })
  end,
})

--- Compute the display width of a directory buffer's longest visible entry.
--- Directory lines use the format `/<path_id>/<icon>/<name>`, where the
--- path_id and separators are concealed. Returns only the icon+name width.
---@param buf_id integer
---@return integer
local function directory_content_width(buf_id)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local max_width = 0
  for _, line in ipairs(lines) do
    local icon, name = line:match('^/%d+/(.-)/(.*)')
    if icon then
      local w = vim.fn.strdisplaywidth(icon) + vim.fn.strdisplaywidth(name)
      if w > max_width then max_width = w end
    end
  end
  return max_width
end

--- Check whether `buf_id` holds a mini.files directory listing.
--- Directory buffers have lines starting with `/<path_id>/`.
---@param buf_id integer
---@return boolean
local function is_directory_buffer(buf_id)
  local first_line = vim.api.nvim_buf_get_lines(buf_id, 0, 1, false)[1] or ''
  return first_line:match('^/%d+/') ~= nil
end

-- Cap window height at 70% of screen; fit directory preview width to content
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesWindowUpdate',
  ---@param args { data: { win_id: integer, buf_id: integer } }
  callback = function(args)
    local win_id = args.data.win_id
    local buf_id = args.data.buf_id
    local config = vim.api.nvim_win_get_config(win_id)

    -- Height cap for all windows
    local max_height = math.floor(vim.o.lines * 0.7)
    if config.height > max_height then
      config.height = max_height
    end

    -- For preview windows showing directories, fit width to content
    local files = require('mini.files')
    if config.width == files.config.windows.width_preview then
      if is_directory_buffer(buf_id) then
        config.width = math.max(directory_content_width(buf_id) + 1, 1)
      end
    end

    vim.api.nvim_win_set_config(win_id, config)
  end,
})

-- Enter opens file and closes explorer, instead of just navigating into it
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    vim.keymap.set('n', '<CR>', function()
      require('mini.files').go_in({ close_on_file = true })
    end, { buffer = args.data.buf_id, desc = 'Open file or expand directory' })
  end,
})

-- H resets navigation to the working directory root
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    vim.keymap.set('n', 'H', function()
      require('mini.files').open(vim.uv.cwd(), false)
    end, { buffer = args.data.buf_id, desc = 'Go to cwd root' })
  end,
})

-- q writes pending changes before closing
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  ---@param args { data: { buf_id: integer } }
  callback = function(args)
    vim.keymap.set('n', 'q', function()
      require('mini.files').synchronize()
      require('mini.files').close()
    end, { buffer = args.data.buf_id, desc = 'Sync and close' })
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
