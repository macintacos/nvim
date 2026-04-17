-- github.com/b0o/incline.nvim
-- Floating filename labels at the bottom-right of each window
vim.pack.add({
  "https://github.com/b0o/incline.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

require("incline").setup({
  window = {
    padding = 0,
    margin = { horizontal = 0, vertical = 2 },
    placement = { vertical = "bottom", horizontal = "right" },
  },
  ignore = {
    floating_wins = false,
    wintypes = function(winid, wintype)
      local zen = package.loaded["snacks"].zen
      if zen.win and not zen.win.closed then
        return winid ~= zen.win.win
      end
      return wintype ~= ""
    end,
  },
  render = function(props)
    local helpers = require("incline.helpers")
    local devicons = require("nvim-web-devicons")
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
    if filename == "" then
      filename = "[No Name]"
    end
    local ft_icon, ft_color = devicons.get_icon_color(filename)
    local modified = vim.bo[props.buf].modified
    return {
      ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
      " ",
      { filename, gui = modified and "bold,italic" or "bold" },
      " ",
      guibg = "#090a0d",
    }
  end,
})
