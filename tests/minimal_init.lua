-- Minimal init for plenary test harness

-- Headless test nvims must never touch the shared ShaDa file. Without this,
-- every spec's child nvim reads and writes ~/.local/state/nvim/*/shada/main.shada
-- alongside the interactive editor; concurrent or signal-killed children
-- interleave their writes and corrupt it (E576, then E136 on every later write).
vim.o.shadafile = "NONE"
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
