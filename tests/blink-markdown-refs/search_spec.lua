local search = require("blink-markdown-refs.search")

-- Helper to create a temp directory with fixture files
local function create_fixtures()
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")

  -- Create markdown files with headings
  local md1 = tmp .. "/README.md"
  vim.fn.writefile({
    "# Getting Started",
    "",
    "Some intro text.",
    "",
    "## Installation",
    "",
    "Run the install command.",
    "",
    "## Usage",
    "",
    "Use the tool like this.",
  }, md1)

  local md2 = tmp .. "/docs/guide.md"
  vim.fn.mkdir(tmp .. "/docs", "p")
  vim.fn.writefile({
    "# User Guide",
    "",
    "Detailed guide content.",
    "",
    "## Configuration",
    "",
    "Configure settings here.",
  }, md2)

  -- Create a non-markdown file
  local py = tmp .. "/main.py"
  vim.fn.writefile({
    "def hello():",
    '    print("hello world")',
    "",
    "def install():",
    '    print("installing")',
  }, py)

  return tmp
end

-- Helper to clean up temp directory
local function cleanup(tmp)
  vim.fn.delete(tmp, "rf")
end

describe("search", function()
  describe("file_item", function()
    it("builds correct file completion item", function()
      local item = search._file_item("/project/src/main.py", "/project", "")
      assert.equals("src/main.py", item.label)
      assert.equals(17, item.kind) -- File
      assert.equals("src/main.py", item.insertText)
      assert.equals("file", item.data.type)
    end)

    it("shows relative path as label", function()
      local item = search._file_item("/project/deep/nested/file.lua", "/project", "")
      assert.equals("deep/nested/file.lua", item.label)
    end)

    it("left-truncates long labels at 30 display columns", function()
      local item = search._file_item("/project/very/deep/nested/path/to/some/file.lua", "/project", "")
      assert.equals(30, vim.fn.strdisplaywidth(item.label))
      assert.is_truthy(item.label:match("^…"))
      assert.is_truthy(item.label:match("file%.lua$"))
    end)
  end)

  describe("heading_item", function()
    it("builds correct heading completion item", function()
      local item = search._heading_item("/project/docs/guide.md", "/project", 5, "Configuration", "")
      assert.equals("docs/guide.md", item.label)
      assert.equals("Configuration", item.labelDetails.description)
      assert.equals(18, item.kind) -- Reference
      assert.equals("docs/guide.md#configuration", item.insertText)
      assert.equals("heading", item.data.type)
    end)

    it("shows path on the left and heading text in description", function()
      local item = search._heading_item("/project/README.md", "/project", 1, "Getting Started", "")
      assert.equals("README.md", item.label)
      assert.equals("Getting Started", item.labelDetails.description)
    end)
  end)

  describe("content_item", function()
    it("builds correct content completion item", function()
      local item = search._content_item("/project/main.py", "/project", 2, 5, 'print("hello world")', "")
      assert.equals("main.py:2:5", item.label)
      assert.equals('print("hello world")', item.labelDetails.description)
      assert.equals(1, item.kind) -- Text
      assert.equals("main.py:2:5", item.insertText)
      assert.equals("content", item.data.type)
    end)

    it("truncates long lines in description", function()
      local long_line = string.rep("a", 100)
      local item = search._content_item("/project/file.txt", "/project", 1, 1, long_line, "")
      assert.is_truthy(item.labelDetails.description:match("%.%.%."))
    end)

    it("shows path:line:col as label", function()
      local item = search._content_item("/project/src/app.js", "/project", 42, 10, "const x = 1", "")
      assert.equals("src/app.js:42:10", item.label)
      assert.equals("const x = 1", item.labelDetails.description)
    end)

    it("left-truncates long path:line:col labels", function()
      local item = search._content_item("/project/very/deep/nested/path/to/file.py", "/project", 42, 5, "code", "")
      assert.equals(30, vim.fn.strdisplaywidth(item.label))
      assert.is_truthy(item.label:match("^…"))
      assert.is_truthy(item.label:match("42:5$"))
    end)
  end)

  describe("ranking", function()
    it("gives exact filename matches highest score_offset", function()
      local item = search._file_item("/project/README.md", "/project", "readme")
      assert.equals(300, item.score_offset)
      assert.is_truthy(item.sortText:match("^0a"))
    end)

    it("gives non-exact filename matches lower score_offset", function()
      local item = search._file_item("/project/README.md", "/project", "xyz")
      assert.equals(100, item.score_offset)
      assert.is_truthy(item.sortText:match("^1a"))
    end)

    it("gives exact heading matches mid-high score_offset", function()
      local item = search._heading_item("/project/docs/guide.md", "/project", 5, "Configuration", "config")
      assert.equals(250, item.score_offset)
      assert.is_truthy(item.sortText:match("^0b"))
    end)

    it("gives non-exact heading matches lower score_offset", function()
      local item = search._heading_item("/project/docs/guide.md", "/project", 5, "Configuration", "xyz")
      assert.equals(50, item.score_offset)
      assert.is_truthy(item.sortText:match("^1b"))
    end)

    it("gives exact content matches mid-high score_offset", function()
      local item = search._content_item("/project/main.py", "/project", 2, 5, 'print("hello")', "hello")
      assert.equals(250, item.score_offset)
      assert.is_truthy(item.sortText:match("^0c"))
    end)

    it("gives non-exact content matches lowest score_offset", function()
      local item = search._content_item("/project/main.py", "/project", 2, 5, 'print("hello")', "xyz")
      assert.equals(0, item.score_offset)
      assert.is_truthy(item.sortText:match("^1c"))
    end)

    it("respects smart case - lowercase query is case-insensitive", function()
      local item = search._file_item("/project/README.md", "/project", "readme")
      assert.equals(300, item.score_offset)
    end)

    it("respects smart case - uppercase query is case-sensitive", function()
      local item = search._file_item("/project/readme.md", "/project", "README")
      assert.equals(100, item.score_offset)
    end)
  end)

  describe("search", function()
    local tmp

    before_each(function()
      tmp = create_fixtures()
    end)

    after_each(function()
      if tmp then
        cleanup(tmp)
      end
    end)

    it("returns file results", function()
      local done = false
      local results

      search.search("", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")
      assert.is_truthy(#results.items > 0, "expected file results")

      -- Should have file items
      local file_items = vim.tbl_filter(function(item)
        return item.data.type == "file"
      end, results.items)
      assert.is_truthy(#file_items >= 3, "expected at least 3 file items (README.md, guide.md, main.py)")
    end)

    it("returns heading results matching query from md files", function()
      local done = false
      local results

      search.search("install", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)
      assert.is_truthy(#heading_items >= 1, "expected at least 1 matching heading item")

      -- Check that Installation heading exists (heading text is in labelDetails.description)
      local found_install = false
      for _, item in ipairs(heading_items) do
        if
          item.labelDetails
          and item.labelDetails.description
          and item.labelDetails.description:match("Installation")
        then
          found_install = true
        end
      end
      assert.is_truthy(found_install, "expected to find Installation heading")
    end)

    it("returns content results when query is 2+ chars", function()
      local done = false
      local results

      search.search("hello", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local content_items = vim.tbl_filter(function(item)
        return item.data.type == "content"
      end, results.items)
      assert.is_truthy(#content_items > 0, "expected content results for 'hello'")
    end)

    it("skips content search for short queries", function()
      local done = false
      local results

      search.search("h", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local content_items = vim.tbl_filter(function(item)
        return item.data.type == "content"
      end, results.items)
      assert.equals(0, #content_items, "expected no content results for single-char query")
    end)

    it("cancel does not crash", function()
      local cancel = search.search("install", tmp, tmp, function() end)
      assert.has_no.errors(function()
        cancel()
      end)
    end)
  end)

  describe("heading filtering without #", function()
    local tmp

    before_each(function()
      tmp = create_fixtures()
    end)

    after_each(function()
      if tmp then
        cleanup(tmp)
      end
    end)

    it("excludes headings that don't match query text", function()
      local done = false
      local results

      search.search("install", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      -- Should only have headings matching "install" (i.e., "Installation")
      for _, item in ipairs(heading_items) do
        local desc = item.labelDetails and item.labelDetails.description or ""
        assert.is_truthy(desc:lower():find("install"), "heading '" .. desc .. "' does not match query 'install'")
      end
      assert.is_truthy(#heading_items > 0, "expected at least one matching heading")
    end)

    it("returns no headings when query is empty", function()
      local done = false
      local results

      search.search("", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)
      assert.equals(0, #heading_items, "expected no heading items for empty query")
    end)

    it("heading filter is smart-case insensitive for lowercase query", function()
      local done = false
      local results

      search.search("config", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      local found = false
      for _, item in ipairs(heading_items) do
        if item.labelDetails and item.labelDetails.description == "Configuration" then
          found = true
        end
      end
      assert.is_truthy(found, "expected 'Configuration' heading to match lowercase 'config'")
    end)

    it("heading filter is smart-case sensitive for mixed-case query", function()
      local done = false
      local results

      search.search("CONFIG", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      -- "CONFIG" (all uppercase) should NOT match "Configuration" (case-sensitive)
      for _, item in ipairs(heading_items) do
        local desc = item.labelDetails and item.labelDetails.description or ""
        assert.is_falsy(
          desc == "Configuration",
          "uppercase 'CONFIG' should not match 'Configuration' in case-sensitive mode"
        )
      end
    end)
  end)

  describe("hash syntax", function()
    local tmp

    before_each(function()
      tmp = create_fixtures()
    end)

    after_each(function()
      if tmp then
        cleanup(tmp)
      end
    end)

    it("foo# returns only files matching foo", function()
      local done = false
      local results

      search.search("README#", tmp, tmp, function(response)
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

      assert.is_truthy(#file_items > 0, "expected at least one file item")
      for _, item in ipairs(file_items) do
        local filename = vim.fn.fnamemodify(item.data.path, ":t")
        assert.is_truthy(filename:lower():find("readme"), "file '" .. filename .. "' does not match 'README'")
      end
    end)

    it("foo# returns all headings from matched files", function()
      local done = false
      local results

      search.search("README#", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      -- README.md has: Getting Started, Installation, Usage
      assert.is_truthy(#heading_items >= 3, "expected at least 3 headings from README.md")

      -- All headings should be from README.md
      for _, item in ipairs(heading_items) do
        local filename = vim.fn.fnamemodify(item.data.path, ":t")
        assert.equals("README.md", filename, "heading should be from README.md")
      end
    end)

    it("foo#bar filters headings within matched files", function()
      local done = false
      local results

      search.search("README#install", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      assert.is_truthy(#heading_items > 0, "expected at least one heading")
      for _, item in ipairs(heading_items) do
        local desc = item.labelDetails and item.labelDetails.description or ""
        assert.is_truthy(desc:lower():find("install"), "heading '" .. desc .. "' does not match 'install'")
        local filename = vim.fn.fnamemodify(item.data.path, ":t")
        assert.equals("README.md", filename, "heading should be from README.md")
      end
    end)

    it("suppresses content search when # is present", function()
      local done = false
      local results

      -- "hello" would normally match main.py content, but # suppresses content search
      search.search("README#hello", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local content_items = vim.tbl_filter(function(item)
        return item.data.type == "content"
      end, results.items)
      assert.equals(0, #content_items, "expected no content results when # is present")
    end)

    it("#heading with empty file part matches headings across all files", function()
      local done = false
      local results

      search.search("#install", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      assert.is_truthy(#heading_items > 0, "expected headings matching 'install'")
    end)

    it("stores heading_query in heading item data.query", function()
      local done = false
      local results

      search.search("README#install", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)

      assert.is_truthy(#heading_items > 0, "expected heading items")
      for _, item in ipairs(heading_items) do
        assert.equals("install", item.data.query, "heading data.query should be the heading portion")
      end
    end)

    it("returns empty headings when no files match file_query", function()
      local done = false
      local results

      search.search("nonexistent#", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)
      assert.equals(0, #heading_items, "expected no headings when file doesn't match")
    end)

    it("heading items rank above file items in # mode", function()
      local done = false
      local results

      search.search("README#install", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)
      local file_items = vim.tbl_filter(function(item)
        return item.data.type == "file"
      end, results.items)

      assert.is_truthy(#heading_items > 0, "expected heading items")
      assert.is_truthy(#file_items > 0, "expected file items")

      -- Every heading should have higher score_offset than every file
      local min_heading_score = math.huge
      for _, item in ipairs(heading_items) do
        if item.score_offset < min_heading_score then
          min_heading_score = item.score_offset
        end
      end
      local max_file_score = -math.huge
      for _, item in ipairs(file_items) do
        if item.score_offset > max_file_score then
          max_file_score = item.score_offset
        end
      end
      assert.is_truthy(
        min_heading_score > max_file_score,
        "heading score_offset ("
          .. min_heading_score
          .. ") should be greater than file score_offset ("
          .. max_file_score
          .. ")"
      )
    end)
  end)

  describe("per-type result limits", function()
    local tmp

    -- Create fixtures with >5 items per type
    before_each(function()
      tmp = vim.fn.tempname()
      vim.fn.mkdir(tmp, "p")

      -- 7 files to exceed the default limit of 5
      for i = 1, 7 do
        vim.fn.writefile({ "file " .. i }, tmp .. "/file" .. i .. ".lua")
      end

      -- 7 headings across markdown files
      vim.fn.writefile({
        "# Heading One",
        "# Heading Two",
        "# Heading Three",
        "# Heading Four",
      }, tmp .. "/headings1.md")
      vim.fn.writefile({
        "# Heading Five",
        "# Heading Six",
        "# Heading Seven",
      }, tmp .. "/headings2.md")

      -- 7 lines matching "matchword" for content search
      local content_lines = {}
      for i = 1, 7 do
        content_lines[i] = "matchword result " .. i
      end
      vim.fn.writefile(content_lines, tmp .. "/content.txt")
    end)

    after_each(function()
      if tmp then
        vim.fn.delete(tmp, "rf")
      end
    end)

    it("limits file results to MAX_RESULTS_PER_TYPE", function()
      local done = false
      local results

      search.search("", tmp, tmp, function(response)
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
      assert.is_truthy(
        #file_items <= search.MAX_RESULTS_PER_TYPE,
        "expected at most " .. search.MAX_RESULTS_PER_TYPE .. " file items, got " .. #file_items
      )
    end)

    it("limits heading results to MAX_RESULTS_PER_TYPE", function()
      local done = false
      local results

      search.search("", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)
      assert.is_truthy(
        #heading_items <= search.MAX_RESULTS_PER_TYPE,
        "expected at most " .. search.MAX_RESULTS_PER_TYPE .. " heading items, got " .. #heading_items
      )
    end)

    it("limits content results to MAX_RESULTS_PER_TYPE", function()
      local done = false
      local results

      search.search("matchword", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)
      assert.is_truthy(done, "search timed out")

      local content_items = vim.tbl_filter(function(item)
        return item.data.type == "content"
      end, results.items)
      assert.is_truthy(
        #content_items <= search.MAX_RESULTS_PER_TYPE,
        "expected at most " .. search.MAX_RESULTS_PER_TYPE .. " content items, got " .. #content_items
      )
    end)

    it("MAX_RESULTS_PER_TYPE is configurable", function()
      local original = search.MAX_RESULTS_PER_TYPE
      search.MAX_RESULTS_PER_TYPE = 2

      local done = false
      local results

      search.search("matchword", tmp, tmp, function(response)
        results = response
        done = true
      end)

      vim.wait(5000, function()
        return done
      end)

      search.MAX_RESULTS_PER_TYPE = original

      assert.is_truthy(done, "search timed out")

      local file_items = vim.tbl_filter(function(item)
        return item.data.type == "file"
      end, results.items)
      local heading_items = vim.tbl_filter(function(item)
        return item.data.type == "heading"
      end, results.items)
      local content_items = vim.tbl_filter(function(item)
        return item.data.type == "content"
      end, results.items)

      assert.is_truthy(#file_items <= 2, "expected at most 2 file items, got " .. #file_items)
      assert.is_truthy(#heading_items <= 2, "expected at most 2 heading items, got " .. #heading_items)
      assert.is_truthy(#content_items <= 2, "expected at most 2 content items, got " .. #content_items)
    end)
  end)
end)
