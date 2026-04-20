-- github.com/RRethy/vim-illuminate
-- Highlights other instances of the word under the cursor
vim.pack.add({ "https://github.com/RRethy/vim-illuminate" })

require("illuminate").configure({
  delay = 200,
  large_file_cutoff = 2000,
  large_file_overrides = { providers = { "lsp" } },
})

-- Defer the Snacks toggle until after snacks.lua has loaded
vim.schedule(function()
  require("snacks")
    .toggle({
      name = "Illuminate",
      get = function()
        return not require("illuminate.engine").is_paused()
      end,
      set = function(enabled)
        local m = require("illuminate")
        if enabled then
          m.resume()
        else
          m.pause()
        end
      end,
    })
    :map("<leader>ux")
end)

local map = require("helpers.mappings").map

local function map_ref(key, dir, buffer)
  map(dir:sub(1, 1):upper() .. dir:sub(2) .. " Reference", "n", key, function()
    require("illuminate")["goto_" .. dir .. "_reference"](false)
  end, { buffer = buffer })
end

map_ref("]]", "next")
map_ref("[[", "prev")

vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()
    map_ref("]]", "next", buffer)
    map_ref("[[", "prev", buffer)
  end,
})
