local projects = require("plugins.projects")

describe("projects._parse", function()
  it("splits zoxide output into a list of dirs", function()
    local out = "/a/one\n/b/two\n/c/three\n"
    assert.same({ "/a/one", "/b/two", "/c/three" }, projects._parse(out))
  end)

  it("drops blank and whitespace-only lines", function()
    local out = "/a/one\n\n   \n/b/two\n"
    assert.same({ "/a/one", "/b/two" }, projects._parse(out))
  end)

  it("trims surrounding whitespace on each line", function()
    -- zoxide --list emits bare paths, but be defensive about stray padding.
    assert.same({ "/a/one", "/b/two" }, projects._parse("  /a/one \n\t/b/two\t\n"))
  end)

  it("returns an empty list for empty output", function()
    assert.same({}, projects._parse(""))
  end)
end)
