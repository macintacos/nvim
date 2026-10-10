local root = vim.fn.fnamemodify(assert(debug.getinfo(1, "S")).source:sub(2), ":p:h:h:h")
-- Only this file's maps are under test, so the plugin is stubbed rather than checked out into .tests/deps.
package.preload.illuminate = function()
  return { configure = function() end }
end
local pack_add = vim.pack.add
vim.pack.add = function() end
local ok, err = pcall(dofile, root .. "/plugin/illuminate.lua")
vim.pack.add = pack_add
assert(ok, err)

---Buffer-local normal maps by lhs, each as its desc or "" so a desc-less map still counts.
---@param buf integer
---@return table<string, string> desc by lhs of the buffer-local normal maps
local function buffer_maps(buf)
  local maps = {}
  for _, keymap in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    maps[keymap.lhs] = keymap.desc or ""
  end
  return maps
end

describe("illuminate reference maps", function()
  it("maps ]] and [[ on the buffer whose filetype is set", function()
    local buf = vim.api.nvim_create_buf(true, false)

    vim.api.nvim_exec_autocmds("FileType", { buffer = buf })

    local maps = buffer_maps(buf)
    assert.equal("Next Reference", maps["]]"])
    assert.equal("Prev Reference", maps["[["])
  end)

  it("leaves scratch buffers' ]] and [[ to them", function()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.bo[buf].filetype = "changeset"

    local maps = buffer_maps(buf)
    assert.is_nil(maps["]]"])
    assert.is_nil(maps["[["])
  end)

  it("maps ]] and [[ on nowrite buffers that hold code", function()
    local buf = vim.api.nvim_create_buf(false, false)
    vim.bo[buf].buftype = "nowrite"

    vim.bo[buf].filetype = "python"

    assert.equal("Next Reference", buffer_maps(buf)["]]"])
  end)
end)
