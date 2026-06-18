local registry = require("plugins.pack-pr.registry")

describe("pack-pr registry", function()
  describe("normalize", function()
    it("derives src, name, and spec_file from a bare owner/repo string", function()
      assert.same({
        repo = "macintacos/agentcomplete.nvim",
        src = "https://github.com/macintacos/agentcomplete.nvim",
        name = "agentcomplete.nvim",
        spec_file = "plugin/agentcomplete.lua",
      }, registry.normalize("macintacos/agentcomplete.nvim"))
    end)

    it("lets a table entry override any derived field", function()
      local r = registry.normalize({ repo = "owner/Thing.nvim", spec_file = "plugin/custom.lua" })
      assert.equal("plugin/custom.lua", r.spec_file)
      assert.equal("Thing.nvim", r.name)
      assert.equal("https://github.com/owner/Thing.nvim", r.src)
    end)

    it("strips a .vim suffix when deriving the spec file", function()
      local r = registry.normalize("owner/foo.vim")
      assert.equal("plugin/foo.lua", r.spec_file)
      assert.equal("foo.vim", r.name)
    end)
  end)

  describe("build", function()
    it("normalizes every entry in the list", function()
      local repos = registry.build({ "a/b.nvim", { repo = "c/d.nvim", name = "dee" } })
      assert.equal(2, #repos)
      assert.equal("b.nvim", repos[1].name)
      assert.equal("dee", repos[2].name)
    end)
  end)
end)
