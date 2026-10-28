vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))
require("mini.pick").setup()

local branches = require("plugins.branches")

---@param kind branches.Kind|"create"
---@param name string
---@return branches.Item
local function item(kind, name)
  return { kind = kind, name = name, text = name, ref = "refs/heads/" .. name } --[[@as branches.Item]]
end

describe("branches._command", function()
  it("does nothing for the current branch", function()
    assert.is_nil(branches._command(item("current", "trunk"), ""))
  end)

  it("switches to a local branch", function()
    assert.are.same({ git = { "switch", "feature" } }, branches._command(item("local", "feature"), "fea"))
  end)

  it("creates a local branch tracking a remote-only one", function()
    assert.are.same(
      { git = { "switch", "--track", "origin/remote-only" } },
      branches._command(item("remote", "origin/remote-only"), "")
    )
  end)

  it("hops to the worktree that holds a branch", function()
    local held = item("worktree", "held")
    held.worktree = "/repo.held"
    assert.are.same({ worktree = "/repo.held" }, branches._command(held, ""))
  end)

  it("creates the typed branch off HEAD", function()
    assert.are.same({ git = { "switch", "-c", "new-thing" } }, branches._command(item("create", ""), "new-thing"))
  end)

  it("creates nothing until a name is typed", function()
    assert.is_nil(branches._command(item("create", ""), ""))
  end)
end)

describe("branches._match", function()
  local items = {
    item("current", "trunk"),
    item("local", "feature-b-long"),
    item("remote", "origin/fb"),
    item("local", "fix"),
    item("create", ""),
  }
  local match = branches._match(items)

  ---@param query string
  ---@return integer[]
  local function run(query)
    local stritems = vim.tbl_map(function(i)
      return i.text
    end, items)
    return match(stritems, { 1, 2, 3, 4, 5 }, query == "" and {} or vim.split(query, ""))
  end

  it("keeps every row in order on an empty query", function()
    assert.are.same({ 1, 2, 4, 3, 5 }, run(""))
  end)

  it("keeps local matches above remote ones however well each matches", function()
    assert.are.same({ 2, 3, 5 }, run("fb"))
  end)

  it("drops the create row once the query names a local branch", function()
    assert.are.same({ 4 }, run("fix"))
  end)
end)

describe("branches._start", function()
  local items = { item("current", "trunk"), item("local", "newest"), item("local", "previous"), item("create", "") }

  it("starts on the branch checked out before this one", function()
    assert.are.equal(3, branches._start(items, "refs/heads/previous"))
  end)

  it("starts on the newest other branch without a previous one", function()
    assert.are.equal(2, branches._start(items, nil))
  end)

  it("starts on the first row when nothing is checked out", function()
    assert.are.equal(1, branches._start({ item("local", "a"), item("create", "") }, nil))
  end)
end)

describe("branches._show", function()
  ---@param kind branches.Kind|"create"
  ---@param name string
  ---@param age string
  ---@return branches.Item
  local function row(kind, name, age)
    local r = item(kind, name)
    r.track, r.age = "", age
    r.author, r.subject = kind == "create" and "" or "Ann", kind == "create" and "" or ("word "):rep(20)
    return r
  end

  it("titles the columns on the top section's header and lines every row up under them", function()
    local items =
      { row("current", "trunk", "2h"), row("remote", "origin/" .. ("x"):rep(60), "3mo"), row("create", "", "") }
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, false, { relative = "editor", row = 0, col = 0, width = 78, height = 8 })
    -- As mini.pick sets up its window.
    vim.wo[win].wrap, vim.wo[win].list, vim.wo[win].listchars = false, true, "extends:…,precedes:…"

    branches._show(items)(buf, items, {})
    vim.cmd.redraw()
    local screen = {}
    for r = 1, 8 do
      local cells = {}
      for c = 1, 78 do
        cells[c] = vim.fn.screenstring(r, c)
      end
      screen[r] = table.concat(cells)
    end
    vim.api.nvim_win_close(win, true)

    ---The first and last screen cells `text` covers in `line`.
    ---@param line string
    ---@param text string
    ---@return integer first
    ---@return integer last
    local function span(line, text)
      local from, to = assert(line:find(text, 1, true))
      return vim.fn.strdisplaywidth(line:sub(1, from)), vim.fn.strdisplaywidth(line:sub(1, to))
    end

    assert.are.equal(" Local", screen[1]:match("^ %S+"))
    assert.are.equal(" Remote", (screen[3]:gsub("%s+$", "")))

    local name = span(screen[2], "trunk")
    assert.are.equal(name, (span(screen[4], "origin/")))

    local _, updated = span(screen[1], "Updated")
    local _, two_hours = span(screen[2], "2h")
    local _, three_months = span(screen[4], "3mo")
    assert.are.same({ updated, updated }, { two_hours, three_months })

    local _, cut = span(screen[4], "x…")
    assert.are.equal(40, cut - name + 1)
    assert.are.same({ "… ", "… " }, { screen[2]:match("… $"), screen[4]:match("… $") })
  end)
end)

describe("branches._top", function()
  local shown = { item("current", "trunk") }
  for i = 1, 10 do
    shown[#shown + 1] = item("remote", "origin/b" .. i)
  end
  shown[#shown + 1] = item("create", "")

  it("keeps the first row on top while the current row fits below it", function()
    assert.are.equal(1, branches._top(shown, 3, 8))
  end)

  it("scrolls just far enough to fit a current row the header lines would push out of view", function()
    assert.are.equal(4, branches._top(shown, 10, 8))
  end)
end)
