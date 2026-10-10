local install = require("plugins.pack-pr.install")

describe("pack-pr install._update_cmd", function()
  it("runs a headless, ShaDa-less nvim that force-updates the plugin and quits", function()
    assert.same({
      vim.v.progpath,
      "--headless",
      "-i",
      "NONE",
      '+lua vim.pack.update({ "x.nvim" }, { force = true })',
      "+qa!",
    }, install._update_cmd("x.nvim"))
  end)
end)

describe("pack-pr install._verify_cmd", function()
  it("compares HEAD with the PR branch on origin", function()
    assert.same({ "git", "-C", "/p", "rev-parse", "HEAD", "origin/feat/x" }, install._verify_cmd("/p", "feat/x"))
  end)

  it("compares HEAD with origin/HEAD for the default branch", function()
    assert.same({ "git", "-C", "/p", "rev-parse", "HEAD", "origin/HEAD" }, install._verify_cmd("/p", nil))
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

  local function run_with(res, branch)
    install._set_runner(function(_, cb)
      cb(res)
    end)
    local verdict, reason
    install.run(entry, branch, function(ok, why)
      verdict, reason = ok, why
    end)
    return verdict, reason
  end

  it("points at the vim.pack log when HEAD did not reach the target", function()
    local ok, reason = run_with({ code = 0, stdout = "abc\ndef\n" }, nil)
    assert.is_false(ok)
    assert.equal("see " .. vim.fs.joinpath(vim.fn.stdpath("log") --[[@as string]], "nvim-pack.log"), reason)
  end)

  it("names the missing branch when origin lacks it", function()
    local ok, reason = run_with({ code = 128, stdout = "abc\n" }, "patch-1")
    assert.is_false(ok)
    assert.equal("origin/patch-1 not found (fork PR?)", reason)
  end)

  it("names origin/HEAD when the default branch cannot be resolved", function()
    local _, reason = run_with({ code = 128, stdout = "abc\n" }, nil)
    assert.equal("origin/HEAD not found", reason)
  end)
end)
