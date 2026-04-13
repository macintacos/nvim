local util = require("blink-markdown-refs.util")

describe("util", function()
  describe("heading_to_anchor", function()
    it("lowercases and slugifies basic text", function()
      assert.equals("my-heading", util.heading_to_anchor("My Heading"))
    end)

    it("strips special characters", function()
      assert.equals("install-v2", util.heading_to_anchor("Install! (v2)"))
    end)

    it("collapses consecutive spaces to single hyphen", function()
      assert.equals("a-b", util.heading_to_anchor("a   b"))
    end)

    it("collapses consecutive hyphens", function()
      assert.equals("a-b", util.heading_to_anchor("a---b"))
    end)

    it("trims leading and trailing hyphens", function()
      assert.equals("hello", util.heading_to_anchor("--hello--"))
    end)

    it("handles empty string", function()
      assert.equals("", util.heading_to_anchor(""))
    end)

    it("preserves underscores", function()
      assert.equals("my_function", util.heading_to_anchor("my_function"))
    end)

    it("handles heading with only special chars", function()
      assert.equals("", util.heading_to_anchor("!@#$%"))
    end)

    it("handles mixed case with numbers", function()
      assert.equals("api-v2-endpoints", util.heading_to_anchor("API v2 Endpoints"))
    end)
  end)

  describe("get_root", function()
    it("returns a string", function()
      local root = util.get_root()
      assert.is_string(root)
    end)

    it("returns the nvim config directory (we're in a git repo)", function()
      local root = util.get_root()
      assert.is_truthy(root:match("nvim$") or root:match("%.config/nvim$"))
    end)
  end)

  describe("truncate_left", function()
    it("returns short strings unchanged", function()
      assert.equals("file.lua", util.truncate_left("file.lua", 30))
    end)

    it("returns string at exact limit unchanged", function()
      local s = string.rep("a", 30)
      assert.equals(s, util.truncate_left(s, 30))
    end)

    it("truncates to correct display width", function()
      local result = util.truncate_left("lua/blink-markdown-refs/search.lua", 30)
      assert.equals(30, vim.fn.strdisplaywidth(result))
      assert.is_truthy(result:match("^…"))
      assert.is_truthy(result:match("search%.lua$"))
    end)

    it("has no space between ellipsis and text", function()
      local result = util.truncate_left("lua/blink-markdown-refs/search.lua", 30)
      -- The character immediately after … should not be a space
      local after_ellipsis = result:match("^…(.)")
      assert.is_truthy(after_ellipsis ~= " ", "no space between ellipsis and text")
    end)

    it("always shows the end of the string", function()
      local result = util.truncate_left("very/deep/nested/path/to/file.py:42:5", 30)
      assert.is_truthy(result:match("file%.py:42:5$"))
    end)

    it("handles single-char limit gracefully", function()
      local result = util.truncate_left("long/path.lua", 5)
      assert.equals(5, vim.fn.strdisplaywidth(result))
      assert.is_truthy(result:match("^…"))
    end)
  end)

  describe("is_smart_exact", function()
    it("matches case-insensitively for lowercase query", function()
      assert.is_true(util.is_smart_exact("readme", "README.md"))
    end)

    it("matches case-sensitively when query has uppercase", function()
      assert.is_true(util.is_smart_exact("README", "README.md"))
      assert.is_false(util.is_smart_exact("README", "readme.md"))
    end)

    it("matches substrings", function()
      assert.is_true(util.is_smart_exact("install", "Installation Guide"))
    end)

    it("returns false for non-matches", function()
      assert.is_false(util.is_smart_exact("xyz", "abc def"))
    end)

    it("returns true for empty query", function()
      assert.is_true(util.is_smart_exact("", "anything"))
    end)
  end)

  describe("relative_path", function()
    it("computes path in same directory", function()
      assert.equals("file.txt", util.relative_path("/home/user/project", "/home/user/project/file.txt"))
    end)

    it("computes path in subdirectory", function()
      assert.equals("sub/file.txt", util.relative_path("/home/user/project", "/home/user/project/sub/file.txt"))
    end)

    it("computes path going up one level", function()
      assert.equals("../file.txt", util.relative_path("/home/user/project/sub", "/home/user/project/file.txt"))
    end)

    it("computes path going up multiple levels", function()
      assert.equals(
        "../../other/file.txt",
        util.relative_path("/home/user/project/a/b", "/home/user/project/other/file.txt")
      )
    end)

    it("handles trailing slash on from_dir", function()
      assert.equals("file.txt", util.relative_path("/home/user/project/", "/home/user/project/file.txt"))
    end)

    it("handles deeply nested paths", function()
      assert.equals("d/e/f.txt", util.relative_path("/a/b/c", "/a/b/c/d/e/f.txt"))
    end)
  end)
end)
