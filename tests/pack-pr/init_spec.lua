local pack_pr = require("plugins.pack-pr")

describe("pack-pr setup", function()
  local saved_get

  before_each(function()
    saved_get = vim.pack.get
    vim.pack.get = function()
      return {
        {
          spec = { src = "https://github.com/macintacos/thing.nvim", name = "thing.nvim" },
          path = "/pack/opt/thing.nvim",
          active = true,
          rev = "0",
        },
        {
          spec = { src = "https://github.com/other/x.nvim", name = "x.nvim" },
          path = "/pack/opt/x.nvim",
          active = true,
          rev = "0",
        },
      }
    end
  end)

  after_each(function()
    vim.pack.get = saved_get
  end)

  it("exposes the owner's installed plugins via registry()", function()
    pack_pr.setup({ owner = "macintacos" })
    local repos = pack_pr.registry()
    assert.equal(1, #repos)
    assert.equal("macintacos/thing.nvim", repos[1].repo)
  end)

  it("registers the :PackPR user command", function()
    pack_pr.setup({ owner = "macintacos" })
    assert.equal(2, vim.fn.exists(":PackPR"))
  end)

  it("binds <leader>Pp to :PackPR", function()
    local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
    dofile(root .. "/plugin/pack-pr.lua")
    assert.equal("<Cmd>PackPR<CR>", vim.fn.maparg("<leader>Pp", "n"))
  end)
end)
