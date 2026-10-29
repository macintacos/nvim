local state = require("plugins.mini-pickers.grep.state")

---@param list string[]
---@param value string
---@return integer
local function index_of(list, value)
  for i, v in ipairs(list) do
    if v == value then
      return i
    end
  end
  error(value .. " not found")
end

describe("grep_state", function()
  describe("decode", function()
    it("round-trips what encode writes", function()
      local s = state.default()
      s.filters = { { kind = "exclude", path = "docs", dir = true } }
      s.sort, s.ignored, s.method, s.query = "hits", true, "plain", "setup"
      assert.same(s, state.decode(state.encode(s)))
    end)

    it("falls back to the defaults for a missing or corrupt value", function()
      assert.same(state.default(), state.decode(nil))
      assert.same(state.default(), state.decode(""))
      assert.same(state.default(), state.decode("{not json"))
      assert.same(state.default(), state.decode("[1,2]"))
    end)

    it("keeps whether each filter names a directory", function()
      local s = state.default()
      s.filters = { { kind = "exclude", path = "a.lua", dir = false }, { kind = "include", path = "lua", dir = true } }
      assert.same(s.filters, state.decode(state.encode(s)).filters)
    end)

    it("reads a filter saved before directories were recorded as a directory", function()
      local s = state.decode(vim.json.encode({ filters = { { kind = "exclude", path = "docs" } } }))
      assert.same({ { kind = "exclude", path = "docs", dir = true } }, s.filters)
    end)

    it("keeps the valid fields of an old or damaged shape and defaults the rest", function()
      local s = state.decode(vim.json.encode({
        sort = "sideways",
        ignored = "yes",
        method = "plain",
        query = 3,
        filters = { { kind = "exclude", path = "a" }, { kind = "maybe", path = "b" }, "junk", { kind = "include" } },
      }))
      assert.same({ { kind = "exclude", path = "a", dir = true } }, s.filters)
      assert.equal("path", s.sort)
      assert.is_false(s.ignored)
      assert.equal("plain", s.method)
      assert.equal("", s.query)
    end)
  end)

  describe("globs", function()
    it("turns excludes into globs anchored to the picker's directory", function()
      local filters =
        { { kind = "exclude", path = "docs", dir = true }, { kind = "include", path = "lua", dir = true } }
      assert.same({ "!/docs" }, state.globs(filters, "/repo", "/repo"))
    end)

    it("rebases filters onto a picker running from a subdirectory", function()
      local filters = { { kind = "exclude", path = "lua/plugins/old", dir = true } }
      assert.same({ "!/plugins/old" }, state.globs(filters, "/repo", "/repo/lua"))
    end)

    it("drops filters outside the picker's directory", function()
      local filters =
        { { kind = "exclude", path = "docs", dir = true }, { kind = "exclude", path = "lua/x", dir = true } }
      assert.same({ "!/x" }, state.globs(filters, "/repo", "/repo/lua"))
    end)

    it("does not take a sibling sharing a prefix for a subdirectory", function()
      assert.same({}, state.globs({ { kind = "exclude", path = "lua2/a", dir = true } }, "/repo", "/repo/lua"))
    end)

    it("escapes glob syntax in a path", function()
      assert.same(
        { "!/a\\[1\\]\\*" },
        state.globs({ { kind = "exclude", path = "a[1]*", dir = true } }, "/repo", "/repo")
      )
    end)
  end)

  describe("paths", function()
    it("turns includes inside the picker's directory into paths relative to it", function()
      local filters = {
        { kind = "exclude", path = "docs", dir = true },
        { kind = "include", path = "lua/x", dir = true },
        { kind = "include", path = "web", dir = true },
      }
      assert.same({ "x" }, state.paths(filters, "/repo", "/repo/lua"))
    end)

    it("keeps glob syntax in a path literal", function()
      assert.same({ "a[1]" }, state.paths({ { kind = "include", path = "a[1]", dir = false } }, "/repo", "/repo"))
    end)
  end)

  describe("command", function()
    local base = {
      "rg",
      "--column",
      "--line-number",
      "--no-heading",
      "--field-match-separator",
      "\\x00",
      "--color=never",
      "--with-filename",
    }

    it("builds mini.pick's rg command for the default state", function()
      local cmd = state.command(state.default(), { pattern = "foo", case = "smart-case" })
      assert.same(vim.list_extend(vim.deepcopy(base), { "--no-fixed-strings", "--smart-case", "--", "foo" }), cmd)
    end)

    it("searches fixed strings with the plain method", function()
      local s = state.default()
      s.method = "plain"
      assert.truthy(vim.tbl_contains(state.command(s, { pattern = "a", case = "smart-case" }), "--fixed-strings"))
    end)

    it("searches ignored paths but not .git when ignored is on", function()
      local s = state.default()
      s.ignored = true
      local cmd = state.command(s, { pattern = "a", case = "smart-case" })
      local at = index_of(cmd, "--no-ignore")
      assert.same({ "--no-ignore", "--glob", "!.git" }, { cmd[at], cmd[at + 1], cmd[at + 2] })
    end)

    it("passes the scope's globs before the filters'", function()
      local cmd = state.command(state.default(), { pattern = "a", case = "smart-case", globs = { "/x.lua", "!/d" } })
      local i = index_of(cmd, "/x.lua")
      assert.same({ "--glob", "/x.lua", "--glob", "!/d" }, vim.list_slice(cmd, i - 1, i + 2))
    end)

    it("searches included paths after the pattern, so rg keeps its ignore rules", function()
      local cmd = state.command(state.default(), { pattern = "a", case = "smart-case", paths = { "web", "-d" } })
      assert.same({ "--", "a", "web", "-d" }, vim.list_slice(cmd, #cmd - 3, #cmd))
    end)

    it("keeps the pattern after -- so a leading dash is not a flag", function()
      local cmd = state.command(state.default(), { pattern = "-x", case = "smart-case" })
      assert.same({ "--", "-x" }, vim.list_slice(cmd, #cmd - 1, #cmd))
    end)
  end)

  describe("label", function()
    it("names the picker plainly when everything is default", function()
      assert.equal("Grep live", state.label(state.default(), "Grep live", "Grep live"))
    end)

    it("drops whatever name the caller calls the default once anything differs", function()
      local s = state.default()
      s.sort = "hits"
      assert.equal("most hits first", state.label(s, "Search", "Search"))
    end)

    it("lists only what differs from the defaults", function()
      local s = state.default()
      s.filters = { { kind = "exclude", path = "docs", dir = true }, { kind = "include", path = "lua", dir = true } }
      s.sort, s.ignored, s.method = "nearest", true, "plain"
      assert.equal("−docs/ +lua/ nearest first ignored plain", state.label(s, "Grep live", "Grep live"))
    end)

    it("draws a trailing slash on a directory filter only", function()
      local s = state.default()
      s.filters = {
        { kind = "exclude", path = "plugin/chezmoi.lua", dir = false },
        { kind = "exclude", path = "docs", dir = true },
      }
      assert.equal("−plugin/chezmoi.lua −docs/", state.label(s, "Grep live", "Grep live"))
    end)

    it("keeps a scoped picker's own name in front of the differences", function()
      local s = state.default()
      s.sort = "hits"
      assert.equal("Grep live (lua/) most hits first", state.label(s, "Grep live (lua/)", "Grep live"))
    end)
  end)

  describe("filters", function()
    it("adds a filter once, normalized", function()
      local s = state.add_filter(state.default(), "exclude", "docs/", true)
      s = state.add_filter(s, "exclude", "./docs", true)
      assert.same({ { kind = "exclude", path = "docs", dir = true } }, s.filters)
    end)

    it("ignores an empty path", function()
      assert.same({}, state.add_filter(state.default(), "include", "  ", true).filters)
    end)

    it("leaves the state it was given untouched", function()
      local s = state.default()
      state.add_filter(s, "exclude", "docs", true)
      assert.same(state.default(), s)
    end)

    it("resets everything but the query", function()
      local s = state.default()
      s.filters, s.sort, s.ignored, s.method, s.query =
        { { kind = "exclude", path = "a", dir = true } }, "hits", true, "plain", "q"
      local expected = state.default()
      expected.query = "q"
      assert.same(expected, state.reset(s))
    end)
  end)
end)
