-- highlight words under the cursor
return {
  "RRethy/vim-illuminate",
  config = function()
    require("illuminate").configure({
      under_cursor = false,
    })
  end,
}
