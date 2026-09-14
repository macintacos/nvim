local data = vim.fn.stdpath("data") .. "/site/pack/"
vim.opt.rtp:prepend(vim.fn.glob(data .. "*/opt/mini.pick", false, true)[1])
require("mini.pick").setup()

local locations = require("plugins.mini-pickers.locations")
local render = require("plugins.mini-pickers.render")

---A location item as mini.extra hands it to `source.show`.
---@param path string
---@param lnum integer
---@param col integer
---@param text string
---@return table
local function location(path, lnum, col, text)
  return { path = "/proj/" .. path, lnum = lnum, col = col, text = ("%s│%d│%d│ %s"):format(path, lnum, col, text) }
end

describe("mini-pickers.locations", function()
  describe("_parse", function()
    it("splits a row into its path and position", function()
      local path, position = locations._parse("lua/init.lua│40│12│ function M.setup()")
      assert.equal("lua/init.lua", path)
      assert.equal("40:12", position)
    end)

    it("keeps a row with no position verbatim", function()
      local path, position = locations._parse("Buffer_3")
      assert.equal("Buffer_3", path)
      assert.is_nil(position)
    end)
  end)

  describe("_show", function()
    it("prints only the path, with the position right-aligned", function()
      local buf = vim.api.nvim_create_buf(false, true)
      locations._show(buf, { location("lua/a.lua", 40, 12, "local x = 1") }, {})

      local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
      assert.is_truthy(line:find("lua/a.lua$"))
      assert.is_nil(line:find("local x"))

      local marks = vim.api.nvim_buf_get_extmarks(buf, render.ns, 0, -1, { details = true })
      local position = vim.tbl_filter(function(mark)
        return mark[4].virt_text_pos == "right_align"
      end, marks)[1]
      assert.same({ { "40:12", "LineNr" } }, position[4].virt_text)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("_match", function()
    it("matches the path, not the hidden line text", function()
      local stritems = { location("lua/a.lua", 1, 1, "needle").text, location("lua/needle.lua", 1, 1, "x").text }
      assert.same({ 2 }, locations._match(stritems, { 1, 2 }, { "n", "e", "e", "d", "l", "e" }))
    end)
  end)
end)
