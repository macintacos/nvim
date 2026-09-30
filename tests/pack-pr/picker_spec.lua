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
  local install = require("plugins.pack-pr.install")
  local tmp, saved, notified, installed, confirmed, cmds, verdict, answer, writes, during

  local function entry()
    return { repo = "o/a", src = "https://github.com/o/a", name = "a", spec_file = tmp, path = "/p" }
  end

  local function read()
    return table.concat(vim.fn.readfile(tmp), "\n")
  end

  before_each(function()
    tmp = vim.fn.tempname() .. ".lua"
    saved = {
      run = install.run,
      confirm = vim.fn.confirm,
      cmd = vim.cmd,
      notify = vim.notify,
      writefile = vim.fn.writefile,
    }
    notified, installed, confirmed, cmds, writes, during = {}, nil, false, {}, 0, nil
    verdict, answer = true, 1
    install.run = function(e, branch, cb)
      installed = { name = e.name, branch = branch }
      if during then
        during()
      end
      cb(verdict, not verdict and "boom" or nil)
    end
    vim.fn.writefile = function(...)
      writes = writes + 1
      return saved.writefile(...)
    end
    vim.fn.confirm = function()
      confirmed = true
      return answer
    end
    vim.cmd = function(c)
      cmds[#cmds + 1] = c
    end
    vim.notify = function(msg, level)
      notified[#notified + 1] = { msg = msg, level = level }
    end
  end)

  after_each(function()
    install.run = saved.run
    vim.fn.confirm = saved.confirm
    vim.cmd = saved.cmd
    vim.notify = saved.notify
    vim.fn.writefile = saved.writefile
    vim.fn.delete(tmp)
  end)

  it("rewrites a bare spec to the PR branch, installs it, and restarts on Yes", function()
    vim.fn.writefile({ "-- header", 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    picker._apply(entry(), "my-branch")
    assert.is_truthy(read():find('{ src = "https://github.com/o/a", version = "my-branch" }', 1, true))
    assert.same({ name = "a", branch = "my-branch" }, installed)
    assert.same({ "restart +confirm\\ qall" }, cmds)
  end)

  it("leaves Neovim running and says so when the restart is declined", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    answer = 2
    picker._apply(entry(), "b")
    assert.same({}, cmds)
    assert.equal(2, #notified)
    assert.is_truthy(notified[2].msg:find("restart to load", 1, true))
  end)

  it("restores the spec file and offers no restart when the install fails", function()
    local original = { 'vim.pack.add({ "https://github.com/o/a" })' }
    vim.fn.writefile(original, tmp)
    verdict = false
    picker._apply(entry(), "b")
    assert.equal(original[1], read())
    assert.is_false(confirmed)
    assert.same({}, cmds)
    assert.same({ msg = "pack-pr: a did not reach b: boom", level = vim.log.levels.ERROR }, notified[#notified])
  end)

  it("keeps a spec edit made during a failing install", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    verdict = false
    during = function()
      saved.writefile({ "-- edited" }, tmp)
    end
    picker._apply(entry(), "b")
    assert.equal("-- edited", read())
  end)

  it("resets a table-form spec to the default branch and restarts on Yes", function()
    vim.fn.writefile({ 'vim.pack.add({ { src = "https://github.com/o/a", version = "old" } })' }, tmp)
    picker._apply(entry(), nil)
    assert.is_truthy(read():find('vim.pack.add({ "https://github.com/o/a" })', 1, true))
    assert.same({ name = "a" }, installed)
    assert.same({ "restart +confirm\\ qall" }, cmds)
  end)

  it("installs without touching a spec that already names the target, even when the install fails", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    writes = 0
    verdict = false
    picker._apply(entry(), nil)
    assert.same({ name = "a" }, installed)
    assert.equal(0, writes)
  end)

  it("warns and does not install when the src is absent from the spec file", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/other/repo" })' }, tmp)
    local e = entry()
    e.src = "https://github.com/not/here"
    picker._apply(e, "b")
    assert.is_truthy(notified[1].msg:find("no spec"))
    assert.is_nil(installed)
  end)

  it("aborts with an error when the spec file is missing", function()
    local e = entry()
    e.spec_file = "/no/such/pack-pr-test-dir/file.lua"
    picker._apply(e, "b")
    assert.is_nil(installed)
    assert.is_truthy(notified[1].msg:find("not found"))
  end)
end)
