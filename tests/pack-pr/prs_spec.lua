local prs = require("plugins.pack-pr.prs")

describe("pack-pr prs.parse", function()
  it("maps a gh JSON array to PR rows", function()
    local json = vim.json.encode({
      {
        number = 12,
        title = "Fix bug",
        headRefName = "fix-bug",
        author = { login = "alice" },
        url = "https://github.com/o/r/pull/12",
      },
    })
    local rows = prs.parse(json, "o/r")
    assert.equal(1, #rows)
    assert.same({
      repo = "o/r",
      number = 12,
      title = "Fix bug",
      branch = "fix-bug",
      author = "alice",
      url = "https://github.com/o/r/pull/12",
    }, rows[1])
  end)

  it("returns an empty list for empty, nil, or '[]' input", function()
    assert.same({}, prs.parse("", "o/r"))
    assert.same({}, prs.parse(nil, "o/r"))
    assert.same({}, prs.parse("[]", "o/r"))
  end)

  it("returns an empty list for unparseable input", function()
    assert.same({}, prs.parse("not json", "o/r"))
  end)

  it("falls back to '?' when the author is missing", function()
    local json = vim.json.encode({ { number = 1, title = "t", headRefName = "b", url = "u" } })
    local rows = prs.parse(json, "o/r")
    assert.equal("?", rows[1].author)
  end)

  it("maps multiple PRs in order", function()
    local json = vim.json.encode({
      { number = 1, title = "a", headRefName = "ba", author = { login = "x" }, url = "u1" },
      { number = 2, title = "b", headRefName = "bb", author = { login = "y" }, url = "u2" },
    })
    local rows = prs.parse(json, "o/r")
    assert.equal(2, #rows)
    assert.equal(1, rows[1].number)
    assert.equal(2, rows[2].number)
  end)
end)
