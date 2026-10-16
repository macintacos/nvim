vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))
require("mini.pick").setup()

local files = require("plugins.mini-pickers.files")
local render = require("plugins.mini-pickers.render")

---@param s string
---@return string[]
local function chars(s)
  return vim.split(s, "")
end

describe("mini-pickers.files", function()
  describe("_command", function()
    local root = vim.fn.tempname()

    before_each(function()
      vim.fn.mkdir(root .. "/.config", "p")
      vim.fn.writefile({ "" }, root .. "/present.md")
      files.extra = { "present.md", "absent.md", ".config" }
    end)

    after_each(function()
      vim.fn.delete(root, "rf")
    end)

    it("lists through rg, hidden files included and .git left out", function()
      local cmd = files._command(root)
      assert.equal("rg", cmd[1])
      assert.is_true(vim.tbl_contains(cmd, "--files"))
      assert.is_true(vim.tbl_contains(cmd, "--hidden"))
      assert.is_true(vim.tbl_contains(cmd, "!.git"))
      assert.is_true(vim.tbl_contains(cmd, "."))
    end)

    it("appends extra paths that exist", function()
      local cmd = files._command(root)
      assert.is_true(vim.tbl_contains(cmd, "present.md"))
      assert.is_true(vim.tbl_contains(cmd, ".config"))
    end)

    it("drops extra paths this project does not have, which rg would error on", function()
      assert.is_false(vim.tbl_contains(files._command(root), "absent.md"))
    end)
  end)

  describe("_postprocess", function()
    it("strips the ./ prefix the walked directory gets", function()
      assert.same({ "lua/init.lua" }, files._postprocess({ "./lua/init.lua" }))
    end)

    it("collapses an extra path listed under both spellings", function()
      assert.same({ "CLAUDE.md" }, files._postprocess({ "CLAUDE.md", "./CLAUDE.md" }))
    end)

    it("drops the trailing empty line rg's output ends on", function()
      assert.same({ "a.lua" }, files._postprocess({ "./a.lua", "" }))
    end)
  end)
  describe("_match", function()
    it("ranks a filename hit above an equally tight directory hit", function()
      assert.same({ 2, 1 }, files._match({ "buzzer/index.ts", "x/y/buz.ts" }, { 1, 2 }, chars("buz")))
    end)

    it("matches a query that names the filename before its directories", function()
      local stritems = { "foo/bar/baz/buz.ts", "other/buz.ts" }
      assert.same({ 1 }, files._match(stritems, { 1, 2 }, chars("buzfoobar")))
    end)

    it("still matches the directories before the filename", function()
      assert.same({ 1 }, files._match({ "foo/bar/baz/buz.ts" }, { 1 }, chars("foobarbuz")))
    end)

    it("anchors ^ to the start of the path, not the filename", function()
      assert.same({ 1 }, files._match({ "lua/a.lua", "x/lua.lua" }, { 1, 2 }, chars("^lua")))
    end)
  end)

  describe("_show", function()
    ---@type integer
    local buf

    before_each(function()
      buf = vim.api.nvim_create_buf(false, true)
    end)

    after_each(function()
      vim.api.nvim_buf_delete(buf, { force = true })
      vim.o.ignorecase, vim.o.smartcase = false, false
    end)

    ---Each highlight `_show` adds, as the path column it starts on and the text it covers.
    ---@param path string
    ---@return { [1]: integer, [2]: string }[]
    local function highlights(path)
      local line = assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      local offset = #line - #path
      local marks = vim.api.nvim_buf_get_extmarks(buf, render.ns, 0, -1, { details = true })
      return vim.tbl_map(function(mark)
        local details = assert(mark[4])
        assert.equal("MiniPickMatchRanges", details.hl_group)
        return { mark[3] - offset, line:sub(mark[3] + 1, details.end_col) }
      end, marks)
    end

    it("highlights a filename-first hit where the characters sit in the path", function()
      files._show(buf, { "foo/bar/baz/buz.ts" }, chars("buzfoo"))
      local expected = { { 0, "f" }, { 1, "o" }, { 2, "o" }, { 12, "b" }, { 13, "u" }, { 14, "z" } }
      assert.same(expected, highlights("foo/bar/baz/buz.ts"))
    end)

    it("ignores case the way the matcher does under smartcase", function()
      vim.o.ignorecase, vim.o.smartcase = true, true
      files._show(buf, { "Foo/Buz.ts" }, chars("buzfoo"))
      assert.equal(6, #highlights("Foo/Buz.ts"))
    end)

    it("leaves an in-order hit to mini.pick's own highlighting", function()
      files._show(buf, { "foo/bar/baz/buz.ts" }, chars("foobuz"))
      assert.same({}, highlights("foo/bar/baz/buz.ts"))
    end)
  end)
end)
