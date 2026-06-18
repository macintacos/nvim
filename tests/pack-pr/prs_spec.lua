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

describe("pack-pr prs.gather", function()
  after_each(function()
    prs._reset()
  end)

  local function repo(name)
    return { repo = name }
  end

  it("aggregates PRs across repos and reports no errors on success", function()
    prs._set_runner(function(name, cb)
      local data = name == "o/a"
          and { { number = 1, title = "a", headRefName = "ba", author = { login = "x" }, url = "u1" } }
        or { { number = 2, title = "b", headRefName = "bb", author = { login = "y" }, url = "u2" } }
      cb({ code = 0, stdout = vim.json.encode(data), stderr = "" })
    end)
    local got_prs, got_errors
    prs.gather({ repo("o/a"), repo("o/b") }, function(p, e)
      got_prs, got_errors = p, e
    end)
    assert.equal(2, #got_prs)
    assert.equal(0, #got_errors)
  end)

  it("collects an error for a repo whose gh call fails", function()
    prs._set_runner(function(name, cb)
      if name == "o/bad" then
        cb({ code = 1, stdout = "", stderr = "HTTP 401: Bad credentials" })
      else
        cb({ code = 0, stdout = "[]", stderr = "" })
      end
    end)
    local got_prs, got_errors
    prs.gather({ repo("o/ok"), repo("o/bad") }, function(p, e)
      got_prs, got_errors = p, e
    end)
    assert.equal(0, #got_prs)
    assert.equal(1, #got_errors)
    assert.equal("o/bad", got_errors[1].repo)
    assert.is_truthy(got_errors[1].message:find("401"))
  end)

  it("invokes the callback immediately for an empty repo list", function()
    local called = false
    prs.gather({}, function(p, e)
      called = true
      assert.same({}, p)
      assert.same({}, e)
    end)
    assert.is_true(called)
  end)
end)
