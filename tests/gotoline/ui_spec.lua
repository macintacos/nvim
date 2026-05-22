local ui = require("plugins.gotoline.ui")
local h = ui._handlers

local function state(results, selected)
  return {
    results = results or {},
    selected = selected or 1,
    locked_file = nil,
  }
end

describe("gotoline.ui._handlers", function()
  describe("select_next", function()
    it("advances to the next result", function()
      local s = state({ { path = "a" }, { path = "b" }, { path = "c" } }, 1)
      h.select_next(s)
      assert.equal(2, s.selected)
    end)

    it("wraps from the last result to the first", function()
      local s = state({ { path = "a" }, { path = "b" } }, 2)
      h.select_next(s)
      assert.equal(1, s.selected)
    end)

    it("is a no-op when there are no results", function()
      local s = state({}, 1)
      h.select_next(s)
      assert.equal(1, s.selected)
    end)
  end)

  describe("select_prev", function()
    it("moves to the previous result", function()
      local s = state({ { path = "a" }, { path = "b" }, { path = "c" } }, 2)
      h.select_prev(s)
      assert.equal(1, s.selected)
    end)

    it("wraps from the first result to the last", function()
      local s = state({ { path = "a" }, { path = "b" }, { path = "c" } }, 1)
      h.select_prev(s)
      assert.equal(3, s.selected)
    end)

    it("is a no-op when there are no results", function()
      local s = state({}, 1)
      h.select_prev(s)
      assert.equal(1, s.selected)
    end)
  end)

  describe("lock", function()
    it("sets locked_file to the selected result and returns '<file>:'", function()
      local s = state({ { path = "lua/foo.lua" }, { path = "bar.lua" } }, 1)
      local prompt = h.lock(s)
      assert.equal("lua/foo.lua", s.locked_file)
      assert.equal("lua/foo.lua:", prompt)
    end)

    it("respects the current selection", function()
      local s = state({ { path = "a.lua" }, { path = "b.lua" } }, 2)
      local prompt = h.lock(s)
      assert.equal("b.lua", s.locked_file)
      assert.equal("b.lua:", prompt)
    end)

    it("returns nil when there are no results", function()
      local s = state({}, 1)
      assert.is_nil(h.lock(s))
      assert.is_nil(s.locked_file)
    end)
  end)

  describe("unlock_if_colon_deleted", function()
    it("unlocks when the prompt has been backspaced into the file path", function()
      local s = { locked_file = "lua/foo.lua" }
      local prompt = h.unlock_if_colon_deleted(s, "lua/foo.lu")
      assert.is_nil(s.locked_file)
      -- The unlocked prompt becomes the file path so the user can keep editing.
      assert.equal("lua/foo.lu", prompt)
    end)

    it("does not unlock while the colon is intact", function()
      local s = { locked_file = "lua/foo.lua" }
      local prompt = h.unlock_if_colon_deleted(s, "lua/foo.lua:42")
      assert.equal("lua/foo.lua", s.locked_file)
      assert.is_nil(prompt)
    end)

    it("restores the anchor when the user edits mid-prefix", function()
      -- Normal-mode cursor movement could let the user mutate the locked
      -- prefix into something neither a prefix-of nor superset-of the anchor.
      -- Restore the anchor instead of unlocking into a garbage filename.
      local s = { locked_file = "foo.lua" }
      local prompt = h.unlock_if_colon_deleted(s, "fXo.lua:")
      assert.equal("foo.lua", s.locked_file)
      assert.equal("foo.lua:", prompt)
    end)
  end)

  describe("lock + unlock round-trip", function()
    it("locks a result, then unlocks back to the file query", function()
      local s = state({ { path = "lua/foo.lua" }, { path = "bar.lua" } }, 1)
      local locked_prompt = h.lock(s)
      assert.equal("lua/foo.lua:", locked_prompt)
      assert.equal("lua/foo.lua", s.locked_file)

      local unlocked_prompt = h.unlock_if_colon_deleted(s, "lua/foo.lu")
      assert.is_nil(s.locked_file)
      assert.equal("lua/foo.lu", unlocked_prompt)
    end)
  end)

  describe("resolve_target", function()
    it("returns nil for empty mode", function()
      assert.is_nil(h.resolve_target({ mode = "empty" }, "/o", "/r"))
    end)

    it("returns nil for filename mode (still picking a file)", function()
      assert.is_nil(h.resolve_target({ mode = "filename", file_query = "x" }, "/o", "/r"))
    end)

    it("targets the origin file for line_only", function()
      local t = h.resolve_target({ mode = "line_only", line = 42 }, "/o/main.lua", "/r")
      assert.same({ file = "/o/main.lua", line = 42 }, t)
    end)

    it("returns nil for line_only when no origin file", function()
      assert.is_nil(h.resolve_target({ mode = "line_only", line = 42 }, nil, "/r"))
    end)

    it("joins root and file for locked with explicit line", function()
      local t = h.resolve_target({ mode = "locked", file = "lua/foo.lua", line = 7 }, "/o", "/r")
      assert.same({ file = "/r/lua/foo.lua", line = 7 }, t)
    end)

    it("defaults to line 1 for locked with no line", function()
      local t = h.resolve_target({ mode = "locked", file = "lua/foo.lua", line = nil }, "/o", "/r")
      assert.same({ file = "/r/lua/foo.lua", line = 1 }, t)
    end)
  end)

  describe("hint_for", function()
    it("returns nil for empty mode", function()
      assert.is_nil(h.hint_for({ mode = "empty" }, 0))
    end)

    it("returns nil for filename mode with no results yet", function()
      assert.is_nil(h.hint_for({ mode = "filename", file_query = "x" }, 0))
    end)

    it("returns the navigate hint for filename mode with results", function()
      local hint = h.hint_for({ mode = "filename", file_query = "x" }, 5)
      assert.is_string(hint)
      assert.is_truthy(hint:find("navigate"))
      assert.is_truthy(hint:find("select"))
    end)

    it("returns the jump hint for line_only mode", function()
      local hint = h.hint_for({ mode = "line_only", line = 1 }, 0)
      assert.is_string(hint)
      assert.is_truthy(hint:find("line"))
      assert.is_truthy(hint:find("jump"))
    end)

    it("returns the jump hint for locked mode", function()
      local hint = h.hint_for({ mode = "locked", file = "f", line = nil }, 0)
      assert.is_string(hint)
      assert.is_truthy(hint:find("line"))
      assert.is_truthy(hint:find("jump"))
    end)
  end)
end)

describe("gotoline.ui open/close", function()
  it("opens the modal and closes cleanly on close()", function()
    local before = #vim.api.nvim_list_wins()
    ui.open()
    local after_open = #vim.api.nvim_list_wins()
    assert.is_true(after_open >= before + 2)
    ui.close()
    -- After close, we should be back to (or below) the original count.
    assert.equal(before, #vim.api.nvim_list_wins())
  end)
end)
