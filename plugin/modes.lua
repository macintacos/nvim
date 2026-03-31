-- github.com/mvllow/modes.nvim
-- Colors the cursorline based on the current mode
vim.pack.add({ "https://github.com/mvllow/modes.nvim" })
require("modes").setup({
  line_opacity = 0.30,
  set_cursor = true,
  set_cursorline = true,
  set_number = true,
  ignore = { "Neotree", "TelescopePrompt" },
})
