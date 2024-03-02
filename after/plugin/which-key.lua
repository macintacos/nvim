-- For legendary.nvim to get which-key suggestions, needs to be loaded before which-key
require("legendary").setup({ extensions = { which_key = { auto_register = true } } })

-- Require which-key
require("main.which-key")
