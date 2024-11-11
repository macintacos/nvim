-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Filetype-specific settings
local autocmd = vim.api.nvim_create_autocmd

vim.cmd([[
    autocmd FileType css setlocal shiftwidth=2 softtabstop=2 tabstop=2
]])

-- Set a bunch of config files to yaml
autocmd({ "BufRead", "BufEnter" }, {
  pattern = { "*lazygit*", "*yamlfmt*", "*yamllint*" },
  callback = function()
    vim.opt_local.filetype = "yaml"
  end,
})

-- Set a bunch of config files to toml
autocmd({ "BufRead", "BufEnter" }, {
  pattern = { "*jakrc*", "*xbarrc*" },
  callback = function()
    vim.opt_local.filetype = "toml"
  end,
})

-- USER COMMANDS

-- "Format" - formats the current buffer using confirm.nvim
vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })

-- "DeleteFile" - attempt to delete the file in the current buffer.
vim.api.nvim_create_user_command("DeleteFile", function()
  local current_buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(current_buf)
  local Snacks = require("snacks")

  -- Check if buffer has a valid file path
  if filepath == "" then
    Snacks.notify.error("No file associated with current buffer")
    return
  end

  -- Confirm with user before deletion using confirm() for single-keystroke input
  local choice = vim.fn.confirm(string.format("Delete %s?", filepath), "&Yes\n&No", 2)

  if choice ~= 1 then -- 1 corresponds to "Yes"
    Snacks.notify.info("File deletion cancelled")
    return
  end

  -- Attempt to delete the file
  local success, err = os.remove(filepath)

  if success then
    Snacks.bufdelete.delete()
    Snacks.notify.info(string.format("'%s' deleted.", filepath))
  else
    Snacks.notify.error(string.format("Failed to delete file: %s", err))
  end
end, {})
