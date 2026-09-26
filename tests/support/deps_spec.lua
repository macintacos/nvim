local deps = require("support.deps")
local support = require("support.git")

describe("support.deps.sync", function()
  local tmp, upstream, dir

  before_each(function()
    tmp = vim.fn.tempname()
    upstream = tmp .. "/upstream"
    dir = tmp .. "/deps"
    vim.fn.mkdir(upstream, "p")
    support.init_repo("main", upstream)
  end)

  after_each(function()
    vim.fn.delete(tmp, "rf")
  end)

  it("checks a dependency out at its pinned revision", function()
    local pinned = support.git({ "rev-parse", "HEAD" }, upstream)
    vim.fn.writefile({ "newer" }, upstream .. "/file")
    support.commit("newer", upstream)

    assert.same({}, deps.sync({ plugin = { src = upstream, rev = pinned } }, dir))
    assert.equal(pinned, support.git({ "rev-parse", "HEAD" }, dir .. "/plugin"))
  end)

  it("moves a checked-out dependency to a changed pin", function()
    local old = support.git({ "rev-parse", "HEAD" }, upstream)
    deps.sync({ plugin = { src = upstream, rev = old } }, dir)
    vim.fn.writefile({ "newer" }, upstream .. "/file")
    local new = support.commit("newer", upstream)

    assert.same({}, deps.sync({ plugin = { src = upstream, rev = new } }, dir))
    assert.equal(new, support.git({ "rev-parse", "HEAD" }, dir .. "/plugin"))
  end)

  it("reports a pin its source cannot supply", function()
    local errors = deps.sync({ plugin = { src = upstream, rev = string.rep("0", 40) } }, dir)

    assert.equal(1, #errors)
    assert.truthy(errors[1]:find("^plugin: "))
  end)
end)
