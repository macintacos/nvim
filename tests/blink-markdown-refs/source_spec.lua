local source_mod = require("plugins.blink-markdown-refs")

describe("blink-markdown-refs source", function()
  local src

  before_each(function()
    src = source_mod.new({})
  end)

  describe("highlight groups", function()
    it("defines BlinkCmpDocMatchChars with bold attribute", function()
      local hl = vim.api.nvim_get_hl(0, { name = "BlinkCmpDocMatchChars" })
      assert.is_true(hl.bold == true, "BlinkCmpDocMatchChars should be bold")
    end)

    it("defines BlinkCmpDocMatchChars with a background color", function()
      local hl = vim.api.nvim_get_hl(0, { name = "BlinkCmpDocMatchChars" })
      assert.is_truthy(hl.bg, "BlinkCmpDocMatchChars should have a bg color")
    end)

    it("defines BlinkCmpDocMatchChars with an orange foreground", function()
      local hl = vim.api.nvim_get_hl(0, { name = "BlinkCmpDocMatchChars" })
      assert.is_truthy(hl.fg, "BlinkCmpDocMatchChars should have a fg color")
      local r = bit.band(bit.rshift(hl.fg, 16), 0xFF)
      local g = bit.band(bit.rshift(hl.fg, 8), 0xFF)
      local b = bit.band(hl.fg, 0xFF)
      assert.is_truthy(r > g and g > b, "should be orange (r > g > b)")
    end)

    it("defines BlinkCmpDocMatchLine with a background color", function()
      local hl = vim.api.nvim_get_hl(0, { name = "BlinkCmpDocMatchLine" })
      assert.is_truthy(hl.bg, "BlinkCmpDocMatchLine should have a bg color")
    end)
  end)

  describe("new", function()
    it("returns a table", function()
      assert.is_table(src)
    end)

    it("has expected methods", function()
      assert.is_function(src.enabled)
      assert.is_function(src.get_trigger_characters)
      assert.is_function(src.get_completions)
      assert.is_function(src.resolve)
      assert.is_function(src.execute)
    end)
  end)

  describe("get_trigger_characters", function()
    it("returns @ and ! as triggers", function()
      local chars = src:get_trigger_characters()
      assert.same({ "@", "!" }, chars)
    end)
  end)

  describe("enabled", function()
    it("returns true for markdown filetype", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].filetype = "markdown"
      assert.is_true(src:enabled())
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns false for non-markdown filetype", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].filetype = "lua"
      assert.is_false(src:enabled())
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("resolve", function()
    it("provides a custom draw function that bypasses code fences", function()
      local tmp = vim.fn.tempname() .. ".lua"
      vim.fn.writefile({ "local x = 1", "local y = 2", "return x + y" }, tmp)

      local item = { data = { type = "file", path = tmp, line = nil, raw_path = tmp } }
      local resolved
      src:resolve(item, function(result)
        resolved = result
      end)
      vim.wait(2000, function()
        return resolved ~= nil
      end)

      assert.is_not_nil(resolved.documentation)
      assert.is_function(resolved.documentation.draw, "expected custom draw function")
      vim.fn.delete(tmp)
    end)

    it("adds documentation for file items", function()
      local tmp = vim.fn.tempname() .. ".lua"
      vim.fn.writefile({ "local x = 1", "local y = 2", "return x + y" }, tmp)

      local item = { data = { type = "file", path = tmp, line = nil, raw_path = tmp } }
      local resolved
      src:resolve(item, function(result)
        resolved = result
      end)
      vim.wait(2000, function()
        return resolved ~= nil
      end)

      assert.is_not_nil(resolved.documentation)
      assert.is_truthy(resolved.documentation.value:match("local x = 1"))
      vim.fn.delete(tmp)
    end)

    it("does not inject marker text into the preview value", function()
      local tmp = vim.fn.tempname() .. ".py"
      vim.fn.writefile({
        "def hello():",
        '    print("hello world")',
        "",
        "def install():",
        '    print("installing")',
      }, tmp)

      local item = {
        data = { type = "content", path = tmp, line = 2, col = 5, raw_path = tmp .. ":2:5", query = "hello" },
      }
      local resolved
      src:resolve(item, function(result)
        resolved = result
      end)
      vim.wait(2000, function()
        return resolved ~= nil
      end)

      assert.is_not_nil(resolved.documentation)
      local val = resolved.documentation.value
      -- No injected marker text
      assert.is_falsy(val:match("▶"), "should not inject marker text")
      assert.is_falsy(val:match("◀"), "should not inject marker text")
      assert.is_falsy(val:match("<<<"), "should not inject marker text")
      -- The actual file content should be present
      assert.is_truthy(val:match('print%("hello world"%)'))
      vim.fn.delete(tmp)
    end)

    it("provides draw function for content items to highlight matches via extmarks", function()
      local tmp = vim.fn.tempname() .. ".py"
      vim.fn.writefile({
        "def hello():",
        '    print("hello world")',
      }, tmp)

      local item = {
        data = { type = "content", path = tmp, line = 2, col = 5, raw_path = tmp .. ":2:5", query = "hello" },
      }
      local resolved
      src:resolve(item, function(result)
        resolved = result
      end)
      vim.wait(2000, function()
        return resolved ~= nil
      end)

      assert.is_not_nil(resolved.documentation)
      assert.is_function(resolved.documentation.draw, "content items should have custom draw")
      vim.fn.delete(tmp)
    end)

    it("highlights matched heading text in the preview for heading items", function()
      local tmp = vim.fn.tempname() .. ".md"
      vim.fn.writefile({
        "# Getting Started",
        "",
        "Some intro text.",
        "",
        "## Installation",
      }, tmp)

      local item = {
        data = { type = "heading", path = tmp, line = 5, raw_path = tmp, query = "install" },
      }
      local resolved
      src:resolve(item, function(result)
        resolved = result
      end)
      vim.wait(2000, function()
        return resolved ~= nil
      end)

      assert.is_not_nil(resolved.documentation)
      assert.is_function(resolved.documentation.draw, "heading items should have custom draw with match highlights")

      -- Verify the draw function applies extmarks by calling it with a mock buffer
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "placeholder" })
      local mock_window = {
        get_buf = function()
          return buf
        end,
      }
      resolved.documentation.draw({ window = mock_window })

      -- Check that extmarks were set on the matched heading line
      local ns = vim.api.nvim_create_namespace("blink-markdown-refs")
      local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
      assert.is_truthy(#marks > 0, "expected extmarks for heading match highlight")

      -- Find the character highlight mark
      local found_char_hl = false
      for _, mark in ipairs(marks) do
        if mark[4] and mark[4].hl_group == "BlinkCmpDocMatchChars" then
          found_char_hl = true
        end
      end
      assert.is_truthy(found_char_hl, "expected BlinkCmpDocMatchChars extmark on heading line")

      vim.api.nvim_buf_delete(buf, { force = true })
      vim.fn.delete(tmp)
    end)
  end)

  describe("setup", function()
    it("has a setup method", function()
      assert.is_function(source_mod.setup)
    end)

    it("accepts projects config without error", function()
      assert.has_no.errors(function()
        source_mod.setup({ projects = { foo = "/tmp/foo" } })
      end)
    end)

    it("works without calling setup", function()
      -- A fresh source should function even if setup was never called
      local fresh_src = source_mod.new({})
      assert.is_function(fresh_src.get_completions)
    end)
  end)

  describe("setup with glob patterns", function()
    local tmp

    before_each(function()
      tmp = vim.fn.tempname()
      vim.fn.mkdir(tmp, "p")
      vim.fn.mkdir(tmp .. "/alpha", "p")
      vim.fn.mkdir(tmp .. "/beta", "p")
      vim.fn.writefile({ "not a dir" }, tmp .. "/file.txt")
    end)

    after_each(function()
      source_mod.setup({ projects = {} })
      if tmp then
        vim.fn.delete(tmp, "rf")
      end
    end)

    it("expands wildcard paths into project entries", function()
      source_mod.setup({ paths = { tmp } })
      -- Should have expanded to alpha and beta (directories only)
      local done = false
      local results

      local ctx = {
        line = "text @!",
        cursor = { 1, 7 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(2, #results.items)

      local names = {}
      for _, item in ipairs(results.items) do
        names[item.label] = true
      end
      assert.is_truthy(names["alpha"])
      assert.is_truthy(names["beta"])
    end)

    it("uses directory basename as project name", function()
      source_mod.setup({ paths = { tmp } })
      local done = false
      local results

      local ctx = {
        line = "text @!al",
        cursor = { 1, 9 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(1, #results.items)
      assert.equal("alpha", results.items[1].label)
      assert.equal(tmp .. "/alpha", results.items[1].labelDetails.description)
    end)

    it("preserves explicit entries alongside globs", function()
      source_mod.setup({ paths = { tmp }, projects = { myproj = "/explicit/path" } })
      local done = false
      local results

      local ctx = {
        line = "text @!",
        cursor = { 1, 7 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      -- alpha + beta from glob, plus myproj explicit
      assert.equal(3, #results.items)
    end)

    it("handles non-existent glob paths gracefully", function()
      assert.has_no.errors(function()
        source_mod.setup({ paths = { "/nonexistent/path" } })
      end)
    end)
  end)

  describe("project completion", function()
    before_each(function()
      source_mod.setup({ projects = { notes = "/tmp/test-notes", code = "/tmp/test-code" } })
    end)

    after_each(function()
      source_mod.setup({ projects = {} })
    end)

    it("returns project names for @!", function()
      local done = false
      local results

      local ctx = {
        line = "text @!",
        cursor = { 1, 7 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(2, #results.items)

      local names = {}
      for _, item in ipairs(results.items) do
        names[item.label] = true
      end
      assert.is_truthy(names["notes"])
      assert.is_truthy(names["code"])
    end)

    it("filters projects by prefix for @!no", function()
      local done = false
      local results

      local ctx = {
        line = "text @!no",
        cursor = { 1, 9 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(1, #results.items)
      assert.equal("notes", results.items[1].label)
    end)

    it("project items have correct kind and insertText", function()
      local done = false
      local results

      local ctx = {
        line = "text @!",
        cursor = { 1, 7 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)

      for _, item in ipairs(results.items) do
        assert.equal(9, item.kind) -- Module
        assert.equal("project", item.data.type)
        assert.is_truthy(item.insertText:match("^!" .. item.label .. "@$"))
        assert.is_truthy(item.filterText:match("^!"), "filterText should start with ! for blink fuzzy matching")
      end
    end)

    it("returns empty when no projects configured", function()
      source_mod.setup({ projects = {} })
      local done = false
      local results

      local ctx = {
        line = "text @!",
        cursor = { 1, 7 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(0, #results.items)
    end)
  end)

  describe("MRU persistence", function()
    local mru_path

    before_each(function()
      -- Use a temp file for MRU so tests don't affect real state
      mru_path = vim.fn.tempname() .. ".json"
      source_mod._set_mru_path(mru_path)
      source_mod.setup({ projects = { alpha = "/tmp/alpha", beta = "/tmp/beta", gamma = "/tmp/gamma" } })
    end)

    after_each(function()
      source_mod.setup({ projects = {} })
      vim.fn.delete(mru_path)
      source_mod._set_mru_path(nil)
    end)

    it("returns empty list when no MRU file exists", function()
      local mru = source_mod._read_mru()
      assert.same({}, mru)
    end)

    it("round-trips MRU data correctly", function()
      source_mod._write_mru({ "beta", "alpha" })
      local mru = source_mod._read_mru()
      assert.same({ "beta", "alpha" }, mru)
    end)

    it("add_to_mru moves name to front and deduplicates", function()
      source_mod._write_mru({ "alpha", "beta", "gamma" })
      source_mod._add_to_mru("gamma")
      local mru = source_mod._read_mru()
      assert.equal("gamma", mru[1])
      -- No duplicates
      local count = 0
      for _, name in ipairs(mru) do
        if name == "gamma" then
          count = count + 1
        end
      end
      assert.equal(1, count)
    end)

    it("project items are sorted by MRU order", function()
      source_mod._write_mru({ "gamma", "alpha" })

      local done = false
      local results

      local ctx = {
        line = "text @!",
        cursor = { 1, 7 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(3, #results.items)

      -- Sort items by sortText to verify ordering
      table.sort(results.items, function(a, b)
        return a.sortText < b.sortText
      end)
      assert.equal("gamma", results.items[1].label)
      assert.equal("alpha", results.items[2].label)
      assert.equal("beta", results.items[3].label)
    end)

    it("executing a project item updates MRU", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "text @!beta@" })

      local ctx = {
        line = "text @!beta@",
        cursor = { 1, 12 },
        bufnr = buf,
      }
      local item = {
        insertText = "!beta@",
        data = { type = "project", project_name = "beta", project_path = "/tmp/beta" },
      }

      src:execute(ctx, item, function() end, function() end)

      local mru = source_mod._read_mru()
      assert.equal("beta", mru[1])

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("project search", function()
    local tmp

    before_each(function()
      tmp = vim.fn.tempname()
      vim.fn.mkdir(tmp, "p")
      vim.fn.writefile({ "# Heading One", "", "Some content." }, tmp .. "/README.md")
      vim.fn.writefile({ "local x = 1" }, tmp .. "/main.lua")
      source_mod.setup({ projects = { testproj = tmp } })
    end)

    after_each(function()
      source_mod.setup({ projects = {} })
      if tmp then
        vim.fn.delete(tmp, "rf")
      end
    end)

    it("returns paths relative to project root, not buffer dir", function()
      local done = false
      local results

      local ctx = {
        line = "text @!testproj@",
        cursor = { 1, 16 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local file_items = vim.tbl_filter(function(item)
        return item.data.type == "file"
      end, results.items)
      assert.is_truthy(#file_items > 0, "expected file items")

      -- Paths should be relative to the project root (e.g., "README.md"), not the buffer dir
      for _, item in ipairs(file_items) do
        assert.is_falsy(item.insertText:match("%.%./"), "path should not contain ../ (got " .. item.insertText .. ")")
      end
    end)

    it("returns file results from project path for @!testproj@", function()
      local done = false
      local results

      local ctx = {
        line = "text @!testproj@",
        cursor = { 1, 16 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")
      assert.is_truthy(#results.items > 0, "expected results from project")

      local file_items = vim.tbl_filter(function(item)
        return item.data.type == "file"
      end, results.items)
      assert.is_truthy(#file_items >= 2, "expected at least 2 file items")
    end)

    it("returns empty for unknown project", function()
      local done = false
      local results

      local ctx = {
        line = "text @!unknown@query",
        cursor = { 1, 20 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(0, #results.items)
    end)

    it("regular @query still uses buffer root", function()
      local done = false
      local results

      local ctx = {
        line = "text @",
        cursor = { 1, 6 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")
      -- Should return results from the nvim config repo, not the test project
      assert.is_truthy(#results.items > 0, "expected results from buffer root")
    end)

    it("tags project search items with data.project", function()
      local done = false
      local results

      local ctx = {
        line = "text @!testproj@",
        cursor = { 1, 16 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")
      assert.is_truthy(#results.items > 0, "expected results")

      for _, item in ipairs(results.items) do
        assert.equal("testproj", item.data.project)
      end
    end)
  end)

  describe("execute with project items", function()
    it("strips !project prefix for project-search items", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "text @!myproj@README.md" })

      local ctx = {
        line = "text @!myproj@README.md",
        cursor = { 1, 23 },
        bufnr = buf,
      }
      local item = {
        insertText = "README.md",
        data = { type = "file", project = "myproj", raw_path = "README.md" },
      }
      local default_called = false

      src:execute(ctx, item, function() end, function()
        default_called = true
      end)

      local line = vim.api.nvim_buf_get_lines(buf, 0, -1, true)[1]
      assert.equal("text @README.md", line)
      assert.is_false(default_called, "should not call default_implementation for project items")

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("positions cursor after inserted text for project items", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_buf_set_lines(buf, 0, -1, true, { "text @!myproj@README.md" })
      -- Place cursor at the window level so nvim_win_set_cursor works
      vim.api.nvim_win_set_cursor(0, { 1, 23 })

      local ctx = {
        line = "text @!myproj@README.md",
        cursor = { 1, 23 },
        bufnr = buf,
      }
      local item = {
        insertText = "README.md",
        data = { type = "file", project = "myproj", raw_path = "README.md" },
      }

      src:execute(ctx, item, function() end, function() end)

      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = vim.api.nvim_buf_get_lines(buf, 0, -1, true)[1]
      -- Cursor should be at or near the end of the inserted text
      -- Neovim clamps to last valid column in normal mode (#line - 1)
      assert.is_truthy(cursor[2] >= #line - 1, "cursor should be at end of inserted text (got " .. cursor[2] .. ")")

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("calls default_implementation for non-project items", function()
      local ctx = {
        line = "text @README.md",
        cursor = { 1, 15 },
        bufnr = vim.api.nvim_get_current_buf(),
      }
      local item = {
        insertText = "README.md",
        data = { type = "file", raw_path = "README.md" },
      }
      local default_called = false

      src:execute(ctx, item, function() end, function()
        default_called = true
      end)

      assert.is_true(default_called, "should call default_implementation for non-project items")
    end)
  end)

  describe("get_completions", function()
    it("returns empty when no @ in line", function()
      local done = false
      local results

      local ctx = {
        line = "no trigger here",
        cursor = { 1, 15 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(0, #results.items)
    end)

    it("returns empty when space follows @", function()
      local done = false
      local results

      local ctx = {
        line = "text @word more",
        cursor = { 1, 15 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(1000, function()
        return done
      end)
      assert.is_truthy(done)
      assert.equal(0, #results.items)
    end)

    it("returns items when @ is typed", function()
      local done = false
      local results

      local ctx = {
        line = "text @",
        cursor = { 1, 6 },
        bufnr = vim.api.nvim_get_current_buf(),
      }

      src:get_completions(ctx, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "get_completions timed out")
      -- Should return at least file and heading results from this repo
      assert.is_truthy(#results.items > 0, "expected some results")
    end)
  end)
end)
