-- Helper for searches in the editor
return {
  "kevinhwang91/nvim-hlslens",
  opts = function()
    return {
      calm_down = true,
      nearest_float_when = "never",
    }
  end,
  keys = {
    {
      "n",
      "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>",
    },
    {
      "N",
      "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>",
    },
    { "*", "*<Cmd>lua require('hlslens').start()<CR>" },
    { "g*", "g*<Cmd>lua require('hlslens').start()<CR>" },
    { "#", "#<Cmd>lua require('hlslens').start()<CR>" },
    { "g#", "g#<Cmd>lua require('hlslens').start()<CR>" },
  },
}
