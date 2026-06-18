local spec = require("plugins.pack-pr.spec")

local SRC = "https://github.com/macintacos/agentcomplete.nvim"

describe("pack-pr spec", function()
  describe("build_spec", function()
    it("returns a bare quoted string when branch is nil", function()
      assert.equal('"' .. SRC .. '"', spec.build_spec(SRC, nil))
    end)

    it("returns a bare quoted string when branch is empty", function()
      assert.equal('"' .. SRC .. '"', spec.build_spec(SRC, ""))
    end)

    it("returns a table form pinned to the branch", function()
      assert.equal('{ src = "' .. SRC .. '", version = "my-branch" }', spec.build_spec(SRC, "my-branch"))
    end)
  end)

  describe("rewrite", function()
    it("rewrites a bare-string spec to the branch table form", function()
      local content = 'vim.pack.add({ "' .. SRC .. '" })\n'
      local out, changed = spec.rewrite(content, SRC, "feat-x")
      assert.is_true(changed)
      assert.equal('vim.pack.add({ { src = "' .. SRC .. '", version = "feat-x" } })\n', out)
    end)

    it("replaces an existing table-form version on a re-switch", function()
      local content = 'vim.pack.add({ { src = "' .. SRC .. '", version = "old" } })\n'
      local out, changed = spec.rewrite(content, SRC, "new")
      assert.is_true(changed)
      assert.equal('vim.pack.add({ { src = "' .. SRC .. '", version = "new" } })\n', out)
    end)

    it("resets a table-form spec back to the bare string when branch is nil", function()
      local content = 'vim.pack.add({ { src = "' .. SRC .. '", version = "old" } })\n'
      local out, changed = spec.rewrite(content, SRC, nil)
      assert.is_true(changed)
      assert.equal('vim.pack.add({ "' .. SRC .. '" })\n', out)
    end)

    it("leaves content unchanged and reports no change when src is absent", function()
      local content = 'vim.pack.add({ "https://github.com/other/plugin.nvim" })\n'
      local out, changed = spec.rewrite(content, SRC, "x")
      assert.is_false(changed)
      assert.equal(content, out)
    end)

    it("does not touch an unquoted comment that mentions the repo", function()
      local content = "-- github.com/macintacos/agentcomplete.nvim\n" .. 'vim.pack.add({ "' .. SRC .. '" })\n'
      local out = spec.rewrite(content, SRC, "feat-x")
      assert.equal(
        "-- github.com/macintacos/agentcomplete.nvim\n"
          .. 'vim.pack.add({ { src = "'
          .. SRC
          .. '", version = "feat-x" } })\n',
        out
      )
    end)

    it("rewrites a table form with a non-quoted version value", function()
      local content = 'vim.pack.add({ { src = "' .. SRC .. '", version = vim.version.range("1.x") } })\n'
      local out, changed = spec.rewrite(content, SRC, "b")
      assert.is_true(changed)
      assert.equal('vim.pack.add({ { src = "' .. SRC .. '", version = "b" } })\n', out)
    end)

    it("reports no change when resetting a spec already in bare form", function()
      local content = 'vim.pack.add({ "' .. SRC .. '" })\n'
      local out, changed = spec.rewrite(content, SRC, nil)
      assert.is_false(changed)
      assert.equal(content, out)
    end)

    it("rewrites only the matching entry in a multi-plugin add list", function()
      local content = 'vim.pack.add({ "https://github.com/a/a", "' .. SRC .. '" })\n'
      local out, changed = spec.rewrite(content, SRC, "b")
      assert.is_true(changed)
      assert.equal('vim.pack.add({ "https://github.com/a/a", { src = "' .. SRC .. '", version = "b" } })\n', out)
    end)
  end)
end)
