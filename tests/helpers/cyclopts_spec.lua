local cyclopts = require("helpers.cyclopts")

describe("cyclopts.under_cursor", function()
  ---@type string
  local root

  local CLI = {
    "from cyclopts import App",
    "",
    "app = App()",
    "app.command(",
    '    "pkg.run:run",',
    '    name="run",',
    ")",
    'app.command("pkg.sub:app", name="sub")',
  }

  ---Edit `src/pkg/cli.py` under the fixture root holding `lines`, cursor on
  ---`row` (1-based) and `col` (0-based).
  ---@param lines string[]
  ---@param row integer
  ---@param col integer
  local function edit(lines, row, col)
    vim.cmd.edit(root .. "/src/pkg/cli.py")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { row, col })
  end

  before_each(function()
    root = vim.fn.tempname()
    vim.fn.mkdir(root .. "/src/pkg/sub", "p")
    root = assert(vim.uv.fs_realpath(root))
    vim.fn.writefile({ "import sys", "", "", "def run(*tokens):", "    pass" }, root .. "/src/pkg/run.py")
    vim.fn.writefile({ "from cyclopts import App", "", "app: App = App()" }, root .. "/src/pkg/sub/__init__.py")
  end)

  after_each(function()
    vim.cmd("silent! %bwipeout!")
    vim.fn.delete(root, "rf")
  end)

  it("points an import path at the function it names", function()
    edit(CLI, 5, 10)
    local location = assert(cyclopts.under_cursor())
    assert.equal(vim.uri_from_fname(root .. "/src/pkg/run.py"), location.uri)
    assert.equal(3, location.range.start.line)
  end)

  it("resolves a package to its __init__.py, from the string's quote", function()
    edit(CLI, 8, 12)
    local location = assert(cyclopts.under_cursor())
    assert.equal(vim.uri_from_fname(root .. "/src/pkg/sub/__init__.py"), location.uri)
    assert.equal(2, location.range.start.line)
  end)

  it("ignores a string that is not the command's first argument", function()
    edit(CLI, 6, 11)
    assert.is_nil(cyclopts.under_cursor())
  end)

  it("ignores a buffer that does not import cyclopts", function()
    edit(vim.list_slice(CLI, 2), 4, 10)
    assert.is_nil(cyclopts.under_cursor())
  end)
end)
