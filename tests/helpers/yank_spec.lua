local yank = require("helpers.yank")

---Porcelain output for one blamed line, as `git blame --porcelain -L n,n` emits it.
---@param sha string
---@return string
local function porcelain(sha)
  return table.concat({
    sha .. " 12 12 1",
    "author Julian Torres",
    "author-mail <julian@excessive.dev>",
    "author-time 1740009600",
    "author-tz -0800",
    "committer Someone Else",
    "committer-mail <someone@example.com>",
    "committer-time 1740096000",
    "committer-tz -0800",
    "summary feat(yank): copy things onto the clipboard",
    "previous 9876543210fedcba9876543210fedcba98765432 lua/helpers/yank.lua",
    "filename lua/helpers/yank.lua",
    "\tlocal M = {}",
  }, "\n")
end

describe("yank._parse_blame", function()
  local sha = "1f2e3d4c5b6a79880123456789abcdef01234567"

  it("pulls the sha, author, time, and summary from porcelain output", function()
    local blame = yank._parse_blame(porcelain(sha))
    assert.same({
      sha = sha,
      author = "Julian Torres",
      time = 1740009600,
      summary = "feat(yank): copy things onto the clipboard",
    }, blame)
  end)

  it("takes the author, not the committer or the author-mail", function()
    local blame = yank._parse_blame(porcelain(sha))
    assert.equal("Julian Torres", blame.author)
    assert.equal(1740009600, blame.time)
  end)

  it("returns nil for an uncommitted line", function()
    assert.is_nil(yank._parse_blame(porcelain(("0"):rep(40))))
  end)

  it("returns nil when git printed something that is not a blame", function()
    assert.is_nil(yank._parse_blame("fatal: no such path 'nope' in HEAD\n"))
  end)
end)
