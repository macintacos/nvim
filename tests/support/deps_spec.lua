local deps = require("support.deps")

describe("support.deps.lock", function()
  ---@type string
  local dir

  before_each(function()
    dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
  end)

  after_each(function()
    vim.fn.delete(dir, "rf")
  end)

  it("holds a second process off until the first lets go", function()
    local path = dir .. "/lock"
    local fd = deps.lock(path)
    local script = dir .. "/take.lua"
    local file = vim.fn.fnamemodify(assert(package.searchpath("support.deps", package.path)), ":p")
    vim.fn.writefile({ ("dofile(%q).lock(%q)"):format(file, path) }, script)
    local code
    vim.system({ vim.v.progpath, "-l", script }, {}, function(result)
      code = result.code
    end)

    assert.is_false(vim.wait(1000, function()
      return code ~= nil
    end))
    vim.uv.fs_close(fd)
    assert.is_true(vim.wait(10000, function()
      return code ~= nil
    end))
    assert.equal(0, code)
  end)
end)
