local rank = require("plugins.mini-pickers.grep.rank")

---@param path string
---@param lnum integer?
---@return string
local function hit(path, lnum)
  return table.concat({ path, lnum or 1, 1, "x" }, "\0")
end

---Paths of `items` in order, one entry per run of hits from the same file.
---@param items string[]
---@return string[]
local function files(items)
  local out = {}
  for _, item in ipairs(items) do
    local path = item:match("^(.-)%z")
    if out[#out] ~= path then
      out[#out + 1] = path
    end
  end
  return out
end

describe("grep_rank", function()
  describe("tier", function()
    it("puts implementation and config files first", function()
      assert.equal(1, rank.tier("lua/plugins/grep.lua"))
      assert.equal(1, rank.tier("mise.toml"))
    end)

    it("sinks tests under a test directory", function()
      for _, path in ipairs({ "tests/a.lua", "lua/test/a.lua", "spec/a.rb", "src/__tests__/a.ts", "testdata/x.txt" }) do
        assert.equal(2, rank.tier(path), path)
      end
    end)

    it("sinks tests named like tests", function()
      for _, path in ipairs({
        "a_spec.lua",
        "a_test.go",
        "a.test.ts",
        "a.spec.js",
        "test_a.py",
        "conftest.py",
        "x.bats",
      }) do
        assert.equal(2, rank.tier("src/" .. path), path)
      end
    end)

    it("does not take a name merely containing test for a test", function()
      assert.equal(1, rank.tier("lua/latest.lua"))
      assert.equal(1, rank.tier("contest/a.py"))
    end)

    it("sinks lockfiles, build output, and local dependencies to the bottom", function()
      for _, path in ipairs({
        "Cargo.lock",
        "package-lock.json",
        "pnpm-lock.yaml",
        "go.sum",
        "bun.lockb",
        "dist/a.js",
        "build/a",
        "out/a",
        "target/a",
        ".next/a",
        "coverage/a",
        "pkg/__pycache__/a.pyc",
        "app.min.js",
        "app.js.map",
        "node_modules/x/index.js",
        ".venv/lib/a.py",
        "venv/a.py",
        "vendor/a.go",
        "lib/site-packages/a.py",
        ".tox/a",
      }) do
        assert.equal(3, rank.tier(path), path)
      end
    end)

    it("ranks a test inside a dependency with the dependency", function()
      assert.equal(3, rank.tier("node_modules/x/a.test.js"))
    end)
  end)

  describe("order", function()
    it("keeps each file's hits together, in rg's order", function()
      local out = rank.order({ hit("b.lua", 9), hit("a.lua", 1), hit("b.lua", 2) }, { sort = "path" })
      assert.same({ hit("a.lua", 1), hit("b.lua", 9), hit("b.lua", 2) }, out)
    end)

    it("sorts by path within a tier, and by tier first", function()
      local out = rank.order({ hit("tests/a.lua"), hit("z.lua"), hit("go.sum"), hit("b.lua") }, { sort = "path" })
      assert.same({ "b.lua", "z.lua", "tests/a.lua", "go.sum" }, files(out))
    end)

    it("orders nearest to the origin file first, ties by path", function()
      local items = { hit("x/y/far.lua"), hit("lua/b/near.lua"), hit("lua/a/sib.lua"), hit("lua/a/also.lua") }
      local out = rank.order(items, { sort = "nearest", origin = "lua/a/me.lua" })
      assert.same({ "lua/a/also.lua", "lua/a/sib.lua", "lua/b/near.lua", "x/y/far.lua" }, files(out))
    end)

    it("counts a file at the root as one directory away from a top-level directory", function()
      local out = rank.order({ hit("plugin/y.lua"), hit("x.lua") }, { sort = "nearest", origin = "lua/me.lua" })
      assert.same({ "x.lua", "plugin/y.lua" }, files(out))
    end)

    it("falls back to path order for nearest without an origin", function()
      local out = rank.order({ hit("b.lua"), hit("a.lua") }, { sort = "nearest" })
      assert.same({ "a.lua", "b.lua" }, files(out))
    end)

    it("orders files with the most hits first, ties by path", function()
      local items = { hit("c.lua"), hit("b.lua"), hit("a.lua"), hit("a.lua", 2), hit("c.lua", 2) }
      assert.same({ "a.lua", "c.lua", "b.lua" }, files(rank.order(items, { sort = "hits" })))
    end)

    it("orders recently used files first, the rest by path", function()
      local items = { hit("d.lua"), hit("c.lua"), hit("b.lua"), hit("a.lua") }
      local out = rank.order(items, { sort = "recent", recent = { ["c.lua"] = 1, ["d.lua"] = 2 } })
      assert.same({ "c.lua", "d.lua", "a.lua", "b.lua" }, files(out))
    end)

    it("keeps tiers above every sort mode", function()
      local items = { hit("tests/a.lua"), hit("tests/a.lua", 2), hit("b.lua") }
      assert.same({ "b.lua", "tests/a.lua" }, files(rank.order(items, { sort = "hits" })))
    end)

    it("passes through lines that are not rg hits, last", function()
      local out = rank.order({ "rg: error", hit("a.lua") }, { sort = "path" })
      assert.same({ hit("a.lua"), "rg: error" }, out)
    end)
  end)

  describe("next_sort", function()
    it("cycles path, nearest, hits, recent, and back", function()
      local seen, sort = {}, rank.SORTS[1]
      for _ = 1, 4 do
        sort = rank.next_sort(sort)
        seen[#seen + 1] = sort
      end
      assert.same({ "nearest", "hits", "recent", "path" }, seen)
    end)
  end)
end)
