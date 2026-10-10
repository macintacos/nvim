-- draculatheme.com/pro
-- Dracula Pro's Van Helsing and Alucard, which the dotfiles deploy as a start package

-- Loads the scheme on VimEnter, once Neovim's own VimEnter handler has decided
-- whether to keep following the terminal's background: it stops for good when
-- anything but its terminal query set 'background' first, and the scheme sets it.
-- Nested, so the ColorScheme handlers run. A scheme a -c, + or -S command
-- already chose stands.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  nested = true,
  callback = function()
    if vim.g.colors_name == nil then
      vim.cmd.colorscheme("dracula-pro")
    end
  end,
})
