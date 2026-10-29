vim.opt.rtp:prepend(require("support.deps").path("mini.pick"))
vim.opt.rtp:prepend(require("support.deps").path("mini.icons"))
vim.opt.rtp:prepend(require("support.deps").path("mini.input"))
require("mini.pick").setup()
require("mini.input").setup()
require("mini.icons").setup()

local grep = require("plugins.mini-pickers.grep")
local grep_state = require("plugins.mini-pickers.grep.state")
local drive = require("support.pick").drive

---An rg hit as `grep_live` delivers it: NUL-separated path, line, column, text.
---@param path string
---@param lnum integer
---@param col integer
---@param text string
---@return string
local function hit(path, lnum, col, text)
  return table.concat({ path, lnum, col, text }, "\0")
end

describe("grep", function()
  describe("_parse", function()
    it("splits an rg hit into path, line number and text", function()
      local path, lnum, text = grep._parse(hit("lua/init.lua", 12, 5, "local M = {}"))
      assert.equal("lua/init.lua", path)
      assert.equal("12", lnum)
      assert.equal("local M = {}", text)
    end)

    it("drops leading indentation, which the header already implies", function()
      local _, _, text = grep._parse(hit("a.lua", 3, 9, "        return true"))
      assert.equal("return true", text)
    end)

    it("keeps a path containing digits and colons intact", function()
      local path = grep._parse(hit("a:b/2.lua", 1, 1, "x"))
      assert.equal("a:b/2.lua", path)
    end)

    it("keeps the separator inside matched text", function()
      local _, _, text = grep._parse(hit("a.lua", 1, 1, "x\0y"))
      assert.equal("x\0y", text)
    end)

    it("shows an unparseable item verbatim, with no header", function()
      local path, lnum, text = grep._parse("not an rg hit")
      assert.is_nil(path)
      assert.is_nil(lnum)
      assert.equal("not an rg hit", text)
    end)
  end)

  describe("_parse column", function()
    it("returns the hit's column last", function()
      local col = select(4, grep._parse(hit("a.lua", 3, 9, "        return true")))
      assert.equal(9, col)
    end)
  end)

  describe("_match_end", function()
    it("ends a literal match after its last byte", function()
      assert.equal(10, grep._match_end("local file = 1", 7, "file", false))
    end)

    it("measures a regex match by what it matched, not the pattern", function()
      assert.equal(10, grep._match_end("foo_bar123", 5, "bar\\d+", false))
    end)

    it("follows the case rule rg searched with", function()
      assert.equal(10, grep._match_end("Local File", 7, "file", true))
      assert.is_nil(grep._match_end("Local File", 7, "file", false))
    end)

    it("treats characters only Vim's regex finds special as literals", function()
      assert.equal(5, grep._match_end("a <b> c", 3, "<b>", false))
    end)

    it("gives up when the pattern does not match where rg said it starts", function()
      assert.is_nil(grep._match_end("xfile", 1, "file", false))
    end)

    it("gives up on syntax Vim's regex cannot compile", function()
      assert.is_nil(grep._match_end("abc", 1, "(?i)abc", false))
    end)
  end)

  describe("_scope", function()
    it("searches a directory whole, unrestricted", function()
      local cwd, globs = grep._scope("/proj/lua", "directory")
      assert.equal("/proj/lua", cwd)
      assert.same({}, globs)
    end)

    it("searches a file from its parent, restricted to itself", function()
      local cwd, globs = grep._scope("/proj/lua/init.lua", "file")
      assert.equal("/proj/lua", cwd)
      assert.same({ "/init.lua" }, globs)
    end)

    it("anchors the glob so a same-named file below does not come along", function()
      local _, globs = grep._scope("/proj/README.md", "file")
      assert.same({ "/README.md" }, globs)
    end)
  end)

  describe("_recency", function()
    it("ranks buffers by last use, then old files, relative to the directory", function()
      local bufs = { { name = "/r/old.lua", lastused = 1 }, { name = "/r/new.lua", lastused = 9 } }
      local ranks = grep._recency("/r", bufs, { "/r/old.lua", "/r/a/gone.lua" })
      assert.same({ ["new.lua"] = 1, ["old.lua"] = 2, ["a/gone.lua"] = 3 }, ranks)
    end)

    it("skips unnamed buffers and files outside the directory", function()
      local ranks = grep._recency("/r", { { name = "", lastused = 5 } }, { "/elsewhere/x.lua" })
      assert.same({}, ranks)
    end)
  end)

  describe("pick", function()
    ---@type string, string
    local dir, cwd

    ---@param rel string
    local function write(rel)
      vim.fn.mkdir(vim.fs.dirname(dir .. "/" .. rel), "p")
      vim.fn.writefile({ "needle" }, dir .. "/" .. rel)
    end

    ---Paths of the picker's items, in order.
    ---@return string[]
    local function item_paths()
      return vim.tbl_map(function(item)
        return (grep._parse(item))
      end, MiniPick.get_picker_items() or {})
    end

    ---Run `steps` in a grep picker, starting from a saved query.
    ---@param steps fun()[]
    local function run(steps)
      local saved = grep_state.default()
      saved.query = "needle"
      vim.g.GrepLiveState = grep_state.encode(saved)
      drive(function()
        grep.pick()
      end, steps)
    end

    local function wait() end

    before_each(function()
      dir = vim.fn.resolve(vim.fn.tempname())
      vim.fn.mkdir(dir, "p")
      for _, rel in ipairs({ "tests/a_spec.lua", "b.lua", "a/c.lua" }) do
        write(rel)
      end
      cwd = vim.fn.getcwd()
      vim.fn.chdir(dir)
    end)

    after_each(function()
      vim.fn.chdir(cwd)
      vim.fn.delete(dir, "rf")
      vim.g.GrepLiveState = nil
    end)

    it("opens on the saved query with its hits ranked", function()
      local loaded, query, paths
      run({
        function()
          loaded = vim.wait(5000, function()
            return #item_paths() > 0
          end)
          query = table.concat(MiniPick.get_picker_query() or {})
          paths = item_paths()
        end,
      })
      assert.is_true(loaded)
      assert.equal("needle", query)
      assert.same({ "a/c.lua", "b.lua", "tests/a_spec.lua" }, paths)
    end)

    it("replaces the selected query with the first character typed", function()
      local query
      run({
        wait,
        function()
          vim.api.nvim_input("x")
        end,
        function()
          query = MiniPick.get_picker_query()
        end,
      })
      assert.same({ "x" }, query)
    end)

    it("clears the selected query on backspace", function()
      local query
      run({
        wait,
        function()
          vim.api.nvim_input("<BS>")
        end,
        function()
          query = MiniPick.get_picker_query()
        end,
      })
      assert.same({}, query)
    end)

    it("keeps the query for editing once an arrow drops the selection", function()
      local query
      run({
        wait,
        function()
          vim.api.nvim_input("<Left>x")
        end,
        function()
          query = table.concat(MiniPick.get_picker_query() or {})
        end,
      })
      assert.equal("needlxe", query)
    end)

    it("keeps a query seeded at start over the saved one", function()
      local query
      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniPickStart",
        once = true,
        callback = function()
          MiniPick.set_picker_query({ "seed" })
        end,
      })
      run({
        wait,
        function()
          query = MiniPick.get_picker_query()
        end,
      })
      assert.same({ "seed" }, query)
    end)

    it("keeps the selection through keys a plugin feeds rather than the user types", function()
      local query
      run({
        wait,
        function()
          vim.api.nvim_feedkeys("zt", "n", false)
        end,
        function()
          vim.api.nvim_input("x")
        end,
        function()
          query = MiniPick.get_picker_query()
        end,
      })
      assert.same({ "x" }, query)
    end)

    describe("removing a filter from the filter list", function()
      local select

      before_each(function()
        select = vim.ui.select
        vim.ui.select = function(_, _, on_choice)
          on_choice(nil, 1)
        end
      end)

      after_each(function()
        vim.ui.select = select
      end)

      ---Remove the first saved filter through <M-f>; return the reopened picker's name.
      ---@param filters mini-pickers.grep.state.Filter[]
      ---@param opts? table Options for `grep.pick`.
      ---@return string?
      local function name_after_removing(filters, opts)
        local saved = grep_state.default()
        saved.filters = filters
        vim.g.GrepLiveState = grep_state.encode(saved)
        local name
        drive(function()
          grep.pick(nil, opts)
        end, {
          wait,
          function()
            vim.api.nvim_input("<M-f>")
          end,
          wait,
          function()
            name = (MiniPick.get_picker_opts() or { source = {} }).source.name
          end,
        })
        -- `drive` returns once the first picker stops; the reopened one runs on.
        assert.is_true(vim.wait(2000, function()
          return name ~= nil and not MiniPick.is_picker_active()
        end))
        return name
      end

      it("reopens naming only the filters left", function()
        local name = name_after_removing({
          { kind = "exclude", path = "docs", dir = true },
          { kind = "exclude", path = "types", dir = true },
        })
        assert.equal("−types/", name)
      end)

      it("reopens on the plain name once no filter is left", function()
        assert.equal("Grep live", name_after_removing({ { kind = "exclude", path = "docs", dir = true } }))
      end)

      it("reopens a scoped grep on its own name", function()
        local name = name_after_removing({ { kind = "exclude", path = "docs", dir = true } }, {
          source = { cwd = dir, name = "Grep live (x/)" },
        })
        assert.equal("Grep live (x/)", name)
      end)
    end)

    it("replaces the selected query with a paste", function()
      local query
      run({
        wait,
        function()
          vim.paste({ "new" }, -1)
        end,
        function()
          query = table.concat(MiniPick.get_picker_query() or {})
        end,
      })
      assert.equal("new", query)
    end)

    it("leaves the next picker alone when the grep never started", function()
      local saved = grep_state.default()
      saved.query = "needle"
      vim.g.GrepLiveState = grep_state.encode(saved)
      local start = MiniPick.start
      MiniPick.start = function() end
      local ok = pcall(grep.pick)
      MiniPick.start = start
      assert.is_true(ok)
      local query
      drive(function()
        MiniPick.start({ source = { items = { "a" } } })
      end, {
        function()
          query = MiniPick.get_picker_query()
        end,
      })
      assert.same({}, query)
    end)

    describe("adding a filter", function()
      local get

      before_each(function()
        get = MiniInput.get
      end)

      after_each(function()
        MiniInput.get = get
      end)

      ---Answer the filter prompt with `answer` in a grep scoped to `a/`; return the saved filters.
      ---@param answer string
      ---@return mini-pickers.grep.state.Filter[]
      local function filters_after(answer)
        MiniInput.get = function()
          return answer
        end
        drive(function()
          grep.pick(nil, { source = { cwd = dir .. "/a", name = "Grep live (a/)" } })
        end, {
          wait,
          function()
            vim.api.nvim_input("<M-x>")
          end,
          wait,
        })
        return grep_state.decode(vim.g.GrepLiveState).filters
      end

      it("adds nothing for an empty answer", function()
        assert.same({}, filters_after(""))
      end)

      it("reads a relative path from the picker's directory", function()
        assert.same({ { kind = "exclude", path = "a/c.lua", dir = false } }, filters_after("c.lua"))
      end)

      it("takes an absolute path as it is", function()
        assert.same({ { kind = "exclude", path = "tests", dir = true } }, filters_after(dir .. "/tests/"))
      end)
    end)

    it("saves the query and sort mode it is left with", function()
      run({
        wait,
        function()
          vim.api.nvim_input("<M-t>")
        end,
        wait,
      })
      local saved = grep_state.decode(vim.g.GrepLiveState)
      assert.equal("needle", saved.query)
      assert.equal("nearest", saved.sort)
    end)
  end)
end)
