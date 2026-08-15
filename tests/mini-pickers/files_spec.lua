local files = require("plugins.mini-pickers.files")

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
end)
