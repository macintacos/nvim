local files = require("plugins.gotoline.files")

local function make_tempdir()
  local p = vim.fn.tempname()
  vim.fn.mkdir(p, "p")
  return p
end

describe("gotoline.files", function()
  describe("root", function()
    it("returns the directory containing .git", function()
      local tmp = make_tempdir()
      vim.fn.mkdir(tmp .. "/.git", "p")
      vim.fn.mkdir(tmp .. "/sub/nested", "p")

      local resolved = files.root(tmp .. "/sub/nested")
      assert.equal(tmp, resolved)

      vim.fn.delete(tmp, "rf")
    end)

    it("falls back to cwd when no .git is found", function()
      local tmp = make_tempdir()
      -- No .git anywhere along the path; we still need a stable fallback.
      local resolved = files.root(tmp)
      assert.is_string(resolved)
      assert.is_true(#resolved > 0)

      vim.fn.delete(tmp, "rf")
    end)

    it("returns the directory itself when .git is in it", function()
      local tmp = make_tempdir()
      vim.fn.mkdir(tmp .. "/.git", "p")

      assert.equal(tmp, files.root(tmp))

      vim.fn.delete(tmp, "rf")
    end)
  end)

  describe("list", function()
    before_each(function()
      files._reset()
    end)

    it("calls the callback with the lister output", function()
      files._set_lister(function(_root, cb)
        cb({ "a.lua", "b.lua" })
      end)

      local got
      files.list("/some/root", function(paths)
        got = paths
      end)

      assert.same({ "a.lua", "b.lua" }, got)
    end)

    it("caches results per root and skips the lister on subsequent calls", function()
      local calls = 0
      files._set_lister(function(_root, cb)
        calls = calls + 1
        cb({ "x.lua" })
      end)

      local first, second
      files.list("/r", function(paths)
        first = paths
      end)
      files.list("/r", function(paths)
        second = paths
      end)

      assert.equal(1, calls)
      assert.same({ "x.lua" }, first)
      assert.same({ "x.lua" }, second)
    end)

    it("invalidate() clears the cache for a root", function()
      local calls = 0
      files._set_lister(function(_root, cb)
        calls = calls + 1
        cb({ "x.lua" })
      end)

      files.list("/r", function() end)
      files.invalidate("/r")
      files.list("/r", function() end)

      assert.equal(2, calls)
    end)

    it("does not cache an empty result (so a failed rg call gets retried)", function()
      local calls = 0
      files._set_lister(function(_root, cb)
        calls = calls + 1
        cb({})
      end)

      files.list("/r", function() end)
      files.list("/r", function() end)

      assert.equal(2, calls)
    end)
  end)
end)
