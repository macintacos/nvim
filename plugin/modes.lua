-- github.com/mvllow/modes.nvim
-- Colors the cursorline based on the current mode
vim.pack.add({ "https://github.com/mvllow/modes.nvim" })
require("modes").setup({
  -- Every mode at 0.30 except visual, which is blended lighter so the selection
  -- stands out against the cursorline.
  line_opacity = {
    copy = 0.30,
    delete = 0.30,
    change = 0.30,
    format = 0.30,
    insert = 0.30,
    replace = 0.30,
    select = 0.30,
    visual = 0.45,
  },
  set_cursor = true,
  -- Left to 'cursorline' from lua/config/options.lua, which is on everywhere.
  -- modes.nvim's own management turns it off on WinLeave, which would leave
  -- unfocused windows with no marker for the line their cursor is on. Mode
  -- colors are applied through window-local 'winhighlight', so they still only
  -- reach the focused window.
  set_cursorline = false,
  set_number = true,
  ignore = { "Neotree", "TelescopePrompt" },
})
