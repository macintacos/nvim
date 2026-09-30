local install = require("plugins.pack-pr.install")

describe("pack-pr install._update_cmd", function()
  it("runs a headless, ShaDa-less nvim that force-updates the plugin and quits", function()
    local cmd = install._update_cmd("x.nvim")
    assert.equal(vim.v.progpath, cmd[1])
    for _, arg in ipairs({ "--headless", "-i", "NONE", "+qa" }) do
      assert.is_true(vim.tbl_contains(cmd, arg), arg)
    end
    assert.is_true(vim.tbl_contains(cmd, '+lua vim.pack.update({ "x.nvim" }, { force = true })'))
  end)
end)

describe("pack-pr install._verify_cmd", function()
  it("compares HEAD with the PR branch on origin", function()
    local cmd = install._verify_cmd("/p", "feat/x")
    assert.equal("origin/feat/x", cmd[#cmd])
    assert.same({ "-C", "/p" }, { cmd[2], cmd[3] })
  end)

  it("compares HEAD with origin/HEAD for the default branch", function()
    local cmd = install._verify_cmd("/p", nil)
    assert.equal("origin/HEAD", cmd[#cmd])
    assert.same({ "-C", "/p" }, { cmd[2], cmd[3] })
  end)
end)

describe("pack-pr install._verified", function()
  it("accepts two equal SHAs from a successful run", function()
    assert.is_true(install._verified({ code = 0, stdout = "abc\nabc\n" }))
  end)

  it("rejects unequal SHAs", function()
    assert.is_false(install._verified({ code = 0, stdout = "abc\ndef\n" }))
  end)

  it("rejects a non-zero exit", function()
    assert.is_false(install._verified({ code = 128, stdout = "abc\nabc\n" }))
  end)

  it("rejects empty stdout", function()
    assert.is_false(install._verified({ code = 0, stdout = "" }))
  end)
end)

describe("pack-pr install.run", function()
  ---@type pack-pr.Repo
  local entry =
    { repo = "o/x.nvim", src = "https://github.com/o/x.nvim", name = "x.nvim", spec_file = "plugin/x.lua", path = "/p" }

  after_each(function()
    install._reset()
  end)

  it("updates, then verifies at entry.path, and reports the verdict", function()
    local calls = {}
    install._set_runner(function(cmd, cb)
      calls[#calls + 1] = cmd
      cb({ code = 0, stdout = "abc\nabc\n" })
    end)
    local verdict
    install.run(entry, "feat", function(ok)
      verdict = ok
    end)
    assert.same(install._update_cmd("x.nvim"), calls[1])
    assert.same(install._verify_cmd("/p", "feat"), calls[2])
    assert.is_true(verdict)
  end)

  it("reports failure when HEAD did not reach the target", function()
    install._set_runner(function(_, cb)
      cb({ code = 0, stdout = "abc\ndef\n" })
    end)
    local verdict
    install.run(entry, nil, function(ok)
      verdict = ok
    end)
    assert.is_false(verdict)
  end)
end)
