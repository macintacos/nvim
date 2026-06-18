-- Minimal init for plenary test harness
-- Find plenary.nvim in vim.pack's install directory
local data = vim.fn.stdpath("data") .. "/site/pack/"
local plenary = vim.fn.glob(data .. "*/opt/plenary.nvim", false, true)[1]
  or vim.fn.glob(data .. "*/start/plenary.nvim", false, true)[1]
if plenary then
  vim.opt.rtp:prepend(plenary)
end
-- Run against the repo tree this init lives in (the repo root is two levels up
-- from tests/minimal_init.lua), so the suite also works from a git worktree —
-- in the normal checkout this resolves to the same path as stdpath("config").
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.cmd("runtime plugin/plenary.vim")
