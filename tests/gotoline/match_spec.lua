local match = require("plugins.gotoline.match")

local function paths_of(results)
  local out = {}
  for i, r in ipairs(results) do
    out[i] = r.path
  end
  return out
end

describe("gotoline.match", function()
  it("returns an empty list for an empty input", function()
    assert.same({}, paths_of(match.rank("foo", {})))
  end)

  it("returns an empty list when no path matches", function()
    assert.same({}, paths_of(match.rank("zzz", { "foo.lua", "bar.lua" })))
  end)

  it("ranks a basename match above a path-only match", function()
    local r = match.rank("foo", {
      "lib/bar/baz/something.lua", -- no match
      "src/foo/baz/quux.lua", -- match in path only (foo is a dirname)
      "src/baz/bar/foo.lua", -- match in basename
    })
    local ps = paths_of(r)
    assert.equal("src/baz/bar/foo.lua", ps[1])
  end)

  it("ranks an exact basename match above a partial basename match", function()
    local r = match.rank("init", {
      "init.lua",
      "lib/initialize_helpers.lua",
    })
    assert.equal("init.lua", paths_of(r)[1])
  end)

  it("ranks a basename prefix match above a mid-basename match", function()
    local r = match.rank("foo", {
      "lib/wfoo.lua", -- basename starts with 'w', 'foo' at position 2
      "lib/foo_helper.lua", -- basename starts with 'foo'
    })
    assert.equal("lib/foo_helper.lua", paths_of(r)[1])
  end)

  it("prefers a shorter path on ties", function()
    local r = match.rank("init.lua", {
      "plugin/init.lua",
      "init.lua",
    })
    assert.equal("init.lua", paths_of(r)[1])
  end)

  it("includes match positions in each result", function()
    local r = match.rank("foo", { "lib/foo.lua" })
    assert.equal(1, #r)
    assert.is_table(r[1].positions)
    assert.is_true(#r[1].positions >= 3)
  end)

  it("is case-insensitive for lowercase queries (smart-case)", function()
    local r = match.rank("readme", { "docs/README.md", "docs/notes.md" })
    assert.equal("docs/README.md", paths_of(r)[1])
  end)

  it("preserves all matching candidates", function()
    local r = match.rank("foo", { "foo.lua", "lib/foo.lua", "src/foobar.lua" })
    assert.equal(3, #r)
  end)
end)
