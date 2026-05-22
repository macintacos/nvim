local parse = require("plugins.gotoline.parse").parse

describe("gotoline.parse", function()
  describe("with no locked file", function()
    it("returns mode=empty for an empty prompt", function()
      local r = parse("", nil)
      assert.equal("empty", r.mode)
      assert.is_nil(r.file_query)
      assert.is_nil(r.file)
      assert.is_nil(r.line)
    end)

    it("treats a bare digit prompt as line_only", function()
      local r = parse("42", nil)
      assert.equal("line_only", r.mode)
      assert.equal(42, r.line)
      assert.is_nil(r.file)
      assert.is_nil(r.file_query)
    end)

    it("treats letters as a filename query", function()
      local r = parse("foo", nil)
      assert.equal("filename", r.mode)
      assert.equal("foo", r.file_query)
      assert.is_nil(r.line)
    end)

    it("treats slash-containing input as a filename query", function()
      local r = parse("foo/bar", nil)
      assert.equal("filename", r.mode)
      assert.equal("foo/bar", r.file_query)
    end)

    it("keeps digits inside a filename query (no lock yet)", function()
      local r = parse("chart2d", nil)
      assert.equal("filename", r.mode)
      assert.equal("chart2d", r.file_query)
      assert.is_nil(r.line)
    end)

    it("ignores trailing whitespace on a numeric prompt", function()
      local r = parse("42  ", nil)
      assert.equal("line_only", r.mode)
      assert.equal(42, r.line)
    end)

    it("treats zero as line_only (clamped at jump time)", function()
      local r = parse("0", nil)
      assert.equal("line_only", r.mode)
      assert.equal(0, r.line)
    end)

    it("treats a negative number as line_only (clamped at jump time)", function()
      local r = parse("-5", nil)
      assert.equal("line_only", r.mode)
      assert.equal(-5, r.line)
    end)
  end)

  describe("with a locked file", function()
    local LOCKED = "lua/plugins/gotoline/init.lua"

    it("returns mode=locked with no line when prompt is just '<file>:'", function()
      local r = parse(LOCKED .. ":", LOCKED)
      assert.equal("locked", r.mode)
      assert.equal(LOCKED, r.file)
      assert.is_nil(r.line)
    end)

    it("parses a line number after the colon", function()
      local r = parse(LOCKED .. ":42", LOCKED)
      assert.equal("locked", r.mode)
      assert.equal(LOCKED, r.file)
      assert.equal(42, r.line)
    end)

    it("ignores trailing whitespace after the line", function()
      local r = parse(LOCKED .. ":42  ", LOCKED)
      assert.equal("locked", r.mode)
      assert.equal(42, r.line)
    end)

    it("returns no line for non-digit trailing input", function()
      -- Garbage after ':' shouldn't yield a line — the UI prevents this
      -- but the parser must not pretend a line exists.
      local r = parse(LOCKED .. ":abc", LOCKED)
      assert.equal("locked", r.mode)
      assert.is_nil(r.line)
    end)

    it("parses line=0 (clamped at jump time)", function()
      local r = parse(LOCKED .. ":0", LOCKED)
      assert.equal("locked", r.mode)
      assert.equal(0, r.line)
    end)

    it("parses a negative line (clamped at jump time)", function()
      local r = parse(LOCKED .. ":-7", LOCKED)
      assert.equal("locked", r.mode)
      assert.equal(-7, r.line)
    end)

    it("falls through to unlocked parsing when prompt does not start with the locked file", function()
      -- Defensive: if the prompt no longer matches the lock, behave as if
      -- unlocked. The UI restores the anchor in this case, but the parser
      -- must not pretend the prompt is still locked.
      local r = parse("totally unrelated", LOCKED)
      assert.equal("filename", r.mode)
      assert.equal("totally unrelated", r.file_query)
    end)
  end)
end)
