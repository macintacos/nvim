-- Minimal init for plenary test harness
-- Find plenary.nvim in vim.pack's install directory
local data = vim.fn.stdpath("data") .. "/site/pack/"
local plenary = vim.fn.glob(data .. "*/opt/plenary.nvim", false, true)[1]
  or vim.fn.glob(data .. "*/start/plenary.nvim", false, true)[1]
if plenary then
  vim.opt.rtp:prepend(plenary)
end
vim.opt.rtp:prepend(vim.fn.stdpath("config"))
vim.cmd("runtime plugin/plenary.vim")
