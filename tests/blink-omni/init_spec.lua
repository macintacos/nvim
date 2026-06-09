local source_mod = require("plugins.blink-omni")

describe("blink-omni source", function()
  local src

  before_each(function()
    src = source_mod.new()
  end)

  describe("new", function()
    it("returns a table", function()
      assert.is_table(src)
    end)

    it("has expected methods", function()
      assert.is_function(src.enabled)
      assert.is_function(src.get_completions)
    end)
  end)

  describe("enabled", function()
    it("returns false when omnifunc is empty", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].omnifunc = ""
      assert.is_false(src:enabled())
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns true when omnifunc is set", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].omnifunc = "syntaxcomplete#Complete"
      assert.is_true(src:enabled())
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe("_to_items", function()
    it("maps a list of strings to label/insertText", function()
      local items = source_mod._to_items({ "font-family", "font-size" })
      assert.equal(2, #items)
      assert.equal("font-family", items[1].label)
      assert.equal("font-family", items[1].insertText)
      assert.equal("font-size", items[2].label)
    end)

    it("maps a list of dicts, preferring abbr for label and word for insertText", function()
      local items = source_mod._to_items({
        { word = "font-family", abbr = "font-family (opt)", menu = "string", info = "Sets the font" },
      })
      assert.equal(1, #items)
      assert.equal("font-family (opt)", items[1].label)
      assert.equal("font-family", items[1].insertText)
      assert.equal("string", items[1].detail)
      assert.equal("Sets the font", items[1].documentation)
    end)

    it("falls back to word for label when abbr is empty", function()
      local items = source_mod._to_items({ { word = "theme", abbr = "" } })
      assert.equal("theme", items[1].label)
      assert.equal("theme", items[1].insertText)
    end)

    it("unwraps the { words = {...} } dict form", function()
      local items = source_mod._to_items({ words = { "a", "b" }, refresh = "always" })
      assert.equal(2, #items)
      assert.equal("a", items[1].label)
      assert.equal("b", items[2].label)
    end)

    it("returns empty list for a non-table result", function()
      assert.same({}, source_mod._to_items(nil))
      assert.same({}, source_mod._to_items(0))
    end)
  end)

  describe("get_completions", function()
    before_each(function()
      -- Fake omnifunc: findstart returns col 5 (0-based), results are two strings.
      vim.cmd([[
        function! TestOmniStrings(findstart, base) abort
          if a:findstart
            return 5
          endif
          return ['font-family', 'font-size']
        endfunction
      ]])
    end)

    it("calls the buffer omnifunc and maps results to items", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].omnifunc = "TestOmniStrings"

      local results
      local ctx = { line = "font font-", cursor = { 1, 10 }, bufnr = buf }
      src:get_completions(ctx, function(response)
        results = response
      end)

      assert.is_truthy(results)
      assert.equal(2, #results.items)
      assert.equal("font-family", results.items[1].label)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("anchors the replacement range at the omnifunc start column", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].omnifunc = "TestOmniStrings"

      local results
      local ctx = { line = "font font-", cursor = { 1, 10 }, bufnr = buf }
      src:get_completions(ctx, function(response)
        results = response
      end)

      local edit = results.items[1].textEdit
      assert.is_truthy(edit)
      assert.equal(5, edit.range.start.character)
      assert.equal(10, edit.range["end"].character)
      assert.equal(0, edit.range.start.line)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns an empty response when omnifunc is unset", function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].omnifunc = ""

      local results
      local ctx = { line = "", cursor = { 1, 0 }, bufnr = buf }
      src:get_completions(ctx, function(response)
        results = response
      end)

      assert.is_truthy(results)
      assert.equal(0, #results.items)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns an empty response when findstart reports no match", function()
      vim.cmd([[
        function! TestOmniNoMatch(findstart, base) abort
          if a:findstart
            return -1
          endif
          return []
        endfunction
      ]])
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      vim.bo[buf].omnifunc = "TestOmniNoMatch"

      local results
      local ctx = { line = "abc", cursor = { 1, 3 }, bufnr = buf }
      src:get_completions(ctx, function(response)
        results = response
      end)

      assert.is_truthy(results)
      assert.equal(0, #results.items)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)
end)
