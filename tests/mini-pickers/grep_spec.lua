local grep = require("plugins.mini-pickers.grep")

---An rg hit as `grep_live` delivers it: NUL-separated path, line, column, text.
---@param path string
---@param lnum integer
---@param col integer
---@param text string
---@return string
local function hit(path, lnum, col, text)
  return table.concat({ path, lnum, col, text }, "\0")
end

describe("grep", function()
  describe("_parse", function()
    it("splits an rg hit into path, line number and text", function()
      local path, lnum, text = grep._parse(hit("lua/init.lua", 12, 5, "local M = {}"))
      assert.equal("lua/init.lua", path)
      assert.equal("12", lnum)
      assert.equal("local M = {}", text)
    end)

    it("drops leading indentation, which the header already implies", function()
      local _, _, text = grep._parse(hit("a.lua", 3, 9, "        return true"))
      assert.equal("return true", text)
    end)

    it("keeps a path containing digits and colons intact", function()
      local path = grep._parse(hit("a:b/2.lua", 1, 1, "x"))
      assert.equal("a:b/2.lua", path)
    end)

    it("keeps the separator inside matched text", function()
      local _, _, text = grep._parse(hit("a.lua", 1, 1, "x\0y"))
      assert.equal("x\0y", text)
    end)

    it("shows an unparseable item verbatim, with no header", function()
      local path, lnum, text = grep._parse("not an rg hit")
      assert.is_nil(path)
      assert.is_nil(lnum)
      assert.equal("not an rg hit", text)
    end)
  end)
end)
