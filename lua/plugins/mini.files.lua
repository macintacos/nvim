-- github.com/nvim-mini/mini.files
-- Interactive column-view file explorer

-- Keymaps specific to mini.files
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    vim.keymap.set('n', '<CR>', function()
      require('mini.files').go_in({ close_on_file = true })
    end, { buffer = args.data.buf_id, desc = 'Open file or expand directory' })
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    vim.keymap.set('n', 'H', function()
      require('mini.files').open(vim.uv.cwd(), false)
    end, { buffer = args.data.buf_id, desc = 'Go to cwd root' })
  end,
})

---@module "lazy"
---@type LazySpec
return {
  "nvim-mini/mini.files",
  version = "*",
  config = true,
  opts = {
    windows = {
      preview = true,
    },
    options = {
      use_as_default_explorer = true,
    }
  }
}
