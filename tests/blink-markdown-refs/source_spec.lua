local source_mod = require("blink-markdown-refs")

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
    it("returns @ as trigger", function()
      local chars = src:get_trigger_characters()
      assert.same({ "@" }, chars)
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
