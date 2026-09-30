local registry = require("plugins.pack-pr.registry")

---@param src string
---@param active boolean?
---@return vim.pack.PlugData
local function plug(src, active)
  local name = src:match("([^/]+)$")
  return {
    spec = { src = src, name = name },
    path = "/pack/opt/" .. name,
    active = active ~= false,
    rev = "0",
  }
end

describe("pack-pr registry", function()
  describe("discover", function()
    it("derives repo, src, name, spec_file and path from an owner's plugin", function()
      assert.same({
        {
          repo = "macintacos/agentcomplete.nvim",
          src = "https://github.com/macintacos/agentcomplete.nvim",
          name = "agentcomplete.nvim",
          spec_file = "plugin/agentcomplete.lua",
          path = "/pack/opt/agentcomplete.nvim",
        },
      }, registry.discover({ plug("https://github.com/macintacos/agentcomplete.nvim") }, "macintacos"))
    end)

    it("strips a .vim suffix when deriving the spec file", function()
      local repos = registry.discover({ plug("https://github.com/macintacos/foo.vim") }, "macintacos")
      assert.equal("plugin/foo.lua", repos[1].spec_file)
      assert.equal("foo.vim", repos[1].name)
    end)

    it("keeps only the owner's plugins", function()
      local repos = registry.discover({
        plug("https://github.com/macintacos/a.nvim"),
        plug("https://github.com/other/b.nvim"),
        plug("https://github.com/macintacos-x/y.nvim"),
        plug("https://github.com/macintacos/c.nvim"),
      }, "macintacos")
      assert.same(
        { "macintacos/a.nvim", "macintacos/c.nvim" },
        vim.tbl_map(function(r)
          return r.repo
        end, repos)
      )
    end)

    it("skips inactive plugins", function()
      assert.same({}, registry.discover({ plug("https://github.com/macintacos/a.nvim", false) }, "macintacos"))
    end)

    it("returns an empty list for no plugins", function()
      assert.same({}, registry.discover({}, "macintacos"))
    end)
  end)
end)
