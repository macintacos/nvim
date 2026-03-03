-- github.com/nvim-mini/mini.files
-- Interactive column-view file explorer

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

-- Cap window height at 70% of screen
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesWindowUpdate',
  callback = function(args)
    local config = vim.api.nvim_win_get_config(args.data.win_id)
    local max_height = math.floor(vim.o.lines * 0.7)
    if config.height > max_height then
      config.height = max_height
      vim.api.nvim_win_set_config(args.data.win_id, config)
    end
  end,
})

-- Enter opens file and closes explorer, instead of just navigating into it
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    vim.keymap.set('n', '<CR>', function()
      require('mini.files').go_in({ close_on_file = true })
    end, { buffer = args.data.buf_id, desc = 'Open file or expand directory' })
  end,
})

-- H resets navigation to the working directory root
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    vim.keymap.set('n', 'H', function()
      require('mini.files').open(vim.uv.cwd(), false)
    end, { buffer = args.data.buf_id, desc = 'Go to cwd root' })
  end,
})

-- q writes pending changes before closing
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
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
