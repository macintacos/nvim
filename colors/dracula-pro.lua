-- Dracula Pro's Van Helsing or Alucard from 'background', in the shared palette's
-- colours. Pro's base forces 'background' to dark and renames the scheme, so a Pro
-- variant named directly would undo every appearance flip; restoring both makes the
-- next flip reload this file.
local background = vim.o.background
local palette = require("helpers.palette")
local roles = palette.active()

if #vim.api.nvim_get_runtime_file("colors/dracula-pro-base.vim", false) == 0 then
  vim.cmd.runtime("colors/default.vim")
elseif roles then
  vim.g["dracula_pro#palette"] = palette.dracula_pro(roles, background)
  vim.cmd.runtime("colors/dracula-pro-base.vim")
  if background == "light" then
    -- Alucard's own links: its menus and inactive status lines sit off the editor.
    vim.api.nvim_set_hl(0, "Pmenu", { link = "DraculaBgLighter" })
    vim.api.nvim_set_hl(0, "PmenuSbar", { link = "DraculaBgLighter" })
    vim.api.nvim_set_hl(0, "StatusLineNC", { link = "TabLine" })
  end
else
  vim.cmd.runtime(("colors/dracula-pro-%s.vim"):format(background == "light" and "alucard" or "van-helsing"))
end

vim.o.background = background
vim.g.colors_name = "dracula-pro"
