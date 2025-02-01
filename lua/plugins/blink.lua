return {
  "Saghen/blink.cmp",
  opts = {
    completion = {
      list = {
        selection = {
          auto_insert = false,
          preselect = false,
        },
      },
    },
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
    },
  },
}
