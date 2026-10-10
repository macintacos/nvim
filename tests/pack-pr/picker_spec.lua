local picker = require("plugins.pack-pr.picker")

describe("pack-pr picker._build_items", function()
  local repos = {
    { repo = "o/a", src = "https://github.com/o/a", name = "a", spec_file = "plugin/a.lua", path = "/p" },
  }

  it("builds a PR item plus a reset sentinel per repo", function()
    local prlist = { { repo = "o/a", number = 7, title = "T", branch = "feat", author = "me", url = "u" } }
    local items = picker._build_items(prlist, repos)
    assert.equal(2, #items)
    local pr_item, reset_item = assert(items[1]), assert(items[2])
    assert.equal("pr", pr_item.kind)
    assert.equal("feat", pr_item.branch)
    assert.equal(repos[1], pr_item.entry)
    assert.equal("reset", reset_item.kind)
    assert.is_nil(reset_item.branch)
    assert.equal(repos[1], reset_item.entry)
  end)

  it("skips PRs whose repo is not in the registry", function()
    local prlist = { { repo = "x/y", number = 1, title = "t", branch = "b", author = "a", url = "u" } }
    local items = picker._build_items(prlist, repos)
    assert.equal(1, #items)
    assert.equal("reset", assert(items[1]).kind)
  end)
end)

describe("pack-pr picker._row", function()
  local repos = {
    { repo = "o/a", src = "https://github.com/o/a", name = "a.nvim", spec_file = "plugin/a.lua", path = "/p" },
    {
      repo = "o/longer",
      src = "https://github.com/o/longer",
      name = "longer.nvim",
      spec_file = "plugin/longer.lua",
      path = "/p",
    },
  }
  local prlist = {
    { repo = "o/a", number = 7, title = "Short title", branch = "feat", author = "me", url = "u" },
    { repo = "o/longer", number = 123, title = "Another one", branch = "fix-it", author = "me", url = "u" },
  }

  local function rows(items, width)
    local columns = picker._columns(items, width)
    return vim.tbl_map(function(item)
      return picker._row(item, columns)
    end, items)
  end

  local function cells_before(text, byte)
    return vim.fn.strdisplaywidth(text:sub(1, byte - 1))
  end

  it("right-aligns PR numbers", function()
    local r = rows(picker._build_items(prlist, repos), 80)
    local _, end7 = r[1].text:find("#7", 1, true)
    local _, end123 = r[2].text:find("#123", 1, true)
    assert.equal(cells_before(r[1].text, end7 + 1), cells_before(r[2].text, end123 + 1))
  end)

  it("starts every row's title at the same column", function()
    local r = rows(picker._build_items(prlist, repos), 80)
    -- A reset row leaves the number cell blank, so its label is the first text
    -- after the plugin name.
    local function label(text, name)
      local _, name_end = text:find("%S+", (text:find(name, 1, true)))
      return text:find("%S", name_end + 1)
    end
    local starts = {
      cells_before(r[1].text, r[1].text:find("Short title", 1, true)),
      cells_before(r[2].text, r[2].text:find("Another one", 1, true)),
      cells_before(r[3].text, label(r[3].text, "a")),
      cells_before(r[4].text, label(r[4].text, "longer")),
    }
    assert.same({ starts[1], starts[1], starts[1], starts[1] }, starts)
  end)

  it("clips a long title and branch so the row fits the window", function()
    local long = {
      { repo = "o/a", number = 7, title = ("word "):rep(20), branch = ("branch-"):rep(8), author = "me", url = "u" },
    }
    local row = rows(picker._build_items(long, repos), 60)[1]
    assert.is_true(vim.fn.strdisplaywidth(row.text) + 2 + vim.fn.strdisplaywidth(row.branch) <= 60)
    assert.equal("…", vim.fn.strcharpart(row.text, vim.fn.strchars(row.text) - 1))
  end)
end)

describe("pack-pr picker._apply (integration)", function()
  local install = require("plugins.pack-pr.install")
  ---@type string
  local tmp
  ---@type table
  local saved
  ---@type { msg: string, level: integer? }[]
  local notified
  ---@type (fun())?
  local during_install
  local installed, confirmed, cmds, install_succeeds, restart_answer, writes

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
    notified, installed, confirmed, cmds, writes, during_install = {}, nil, false, {}, 0, nil
    install_succeeds, restart_answer = true, 1
    install.run = function(e, branch, cb)
      installed = { name = e.name, branch = branch }
      -- Each test assigns this after before_each has built the closure.
      ---@cast during_install (fun())?
      if during_install then
        during_install()
      end
      cb(install_succeeds, not install_succeeds and "boom" or nil)
    end
    vim.fn.writefile = function(...)
      writes = writes + 1
      return saved.writefile(...)
    end
    vim.fn.confirm = function()
      confirmed = true
      return restart_answer
    end
    -- vim.cmd is callable at runtime through a metatable; its stub types it as a table of command shortcuts.
    ---@diagnostic disable-next-line: assign-type-mismatch
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
    restart_answer = 2
    picker._apply(entry(), "b")
    assert.same({}, cmds)
    assert.equal(2, #notified)
    assert.is_truthy(assert(notified[2]).msg:find("restart to load", 1, true))
  end)

  it("restores the spec file and offers no restart when the install fails", function()
    local original = { 'vim.pack.add({ "https://github.com/o/a" })' }
    vim.fn.writefile(original, tmp)
    install_succeeds = false
    picker._apply(entry(), "b")
    assert.equal(original[1], read())
    assert.is_false(confirmed)
    assert.same({}, cmds)
    assert.same({ msg = "pack-pr: a did not reach b: boom", level = vim.log.levels.ERROR }, notified[#notified])
  end)

  it("keeps a spec edit made during a failing install", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/o/a" })' }, tmp)
    install_succeeds = false
    during_install = function()
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
    install_succeeds = false
    picker._apply(entry(), nil)
    assert.same({ name = "a" }, installed)
    assert.equal(0, writes)
  end)

  it("warns and does not install when the src is absent from the spec file", function()
    vim.fn.writefile({ 'vim.pack.add({ "https://github.com/other/repo" })' }, tmp)
    local e = entry()
    e.src = "https://github.com/not/here"
    picker._apply(e, "b")
    assert.is_truthy(assert(notified[1]).msg:find("no spec"))
    assert.is_nil(installed)
  end)

  it("aborts with an error when the spec file is missing", function()
    local e = entry()
    e.spec_file = "/no/such/pack-pr-test-dir/file.lua"
    picker._apply(e, "b")
    assert.is_nil(installed)
    assert.is_truthy(assert(notified[1]).msg:find("not found"))
  end)
end)
