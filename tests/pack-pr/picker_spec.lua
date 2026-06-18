local picker = require("plugins.pack-pr.picker")

describe("pack-pr picker._build_items", function()
  local repos = {
    { repo = "o/a", src = "https://github.com/o/a", name = "a", spec_file = "plugin/a.lua" },
  }

  it("builds a PR item plus a reset sentinel per repo", function()
    local prlist = { { repo = "o/a", number = 7, title = "T", branch = "feat", author = "me", url = "u" } }
    local items = picker._build_items(prlist, repos)
    assert.equal(2, #items)
    assert.equal("pr", items[1].kind)
    assert.equal("feat", items[1].branch)
    assert.equal(repos[1], items[1].entry)
    assert.equal("reset", items[2].kind)
    assert.is_nil(items[2].branch)
    assert.equal(repos[1], items[2].entry)
  end)

  it("skips PRs whose repo is not in the registry", function()
    local prlist = { { repo = "x/y", number = 1, title = "t", branch = "b", author = "a", url = "u" } }
    local items = picker._build_items(prlist, repos)
    assert.equal(1, #items)
    assert.equal("reset", items[1].kind)
  end)
end)

describe("pack-pr picker._apply (integration)", function()
  local tmp, saved_update, saved_notify, updated, notified

  local function entry()
    return { repo = "o/a", src = "https://github.com/o/a", name = "a", spec_file = tmp }
  end

  before_each(function()
    tmp = vim.fn.tempname() .. ".lua"
    saved_update = vim.pack and vim.pack.update
    saved_notify = vim.notify
    updated, notified = nil, nil
    vim.pack = vim.pack or {}
    vim.pack.update = function(names)
      updated = names
    end
    vim.notify = function(msg)
      notified = msg
    end
  end)

  after_each(function()
    if vim.pack then
      vim.pack.update = saved_update
    end
    vim.notify = saved_notify
    vim.fn.delete(tmp)
  end)

  it("rewrites a bare spec to the branch form and refreshes the plugin", function()
    vim.fn.writefile({ "-- header", 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    picker._apply(entry(), "my-branch")
    local content = table.concat(vim.fn.readfile(tmp), "\n")
    assert.is_truthy(content:find('{ src = "https://github.com/o/a", version = "my-branch" }', 1, true))
    assert.same({ "a" }, updated)
  end)

  it("resets a table-form spec back to the bare string when branch is nil", function()
    vim.fn.writefile({ "-- header", 'vim.pack.add({ { src = "https://github.com/o/a", version = "old" } })' }, tmp)
    picker._apply(entry(), nil)
    local content = table.concat(vim.fn.readfile(tmp), "\n")
    assert.is_truthy(content:find('vim.pack.add({ "https://github.com/o/a" })', 1, true))
    assert.same({ "a" }, updated)
  end)

  it("warns and does not refresh when the src is absent from the spec file", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/other/repo" })' }, tmp)
    local e = entry()
    e.src = "https://github.com/not/here"
    picker._apply(e, "b")
    assert.is_truthy(notified and notified:find("no spec"))
    assert.is_nil(updated)
  end)

  it("is a no-op when resetting a spec already on the default branch", function()
    vim.fn.writefile({ "-- header", 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    picker._apply(entry(), nil)
    assert.is_nil(updated)
    assert.is_truthy(notified and notified:find("up to date"))
    local content = table.concat(vim.fn.readfile(tmp), "\n")
    assert.is_truthy(content:find('vim.pack.add({ "https://github.com/o/a" })', 1, true))
  end)

  it("aborts with an error when the spec file is missing", function()
    local e = entry()
    e.spec_file = "/no/such/pack-pr-test-dir/file.lua"
    picker._apply(e, "b")
    assert.is_nil(updated)
    assert.is_truthy(notified and notified:find("not found"))
  end)

  it("reports an error when vim.pack.update fails", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    vim.pack.update = function()
      error("boom")
    end
    picker._apply(entry(), "b")
    assert.is_truthy(notified and notified:find("failed"))
  end)
end)
