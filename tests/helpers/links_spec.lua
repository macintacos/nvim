local links = require("helpers.links")

describe("links.under_cursor", function()
  ---@type string
  local root
  ---@type string
  local cwd

  ---Edit `name` under the fixture root holding `line`, cursor on `col` (0-based).
  ---@param name string
  ---@param line string
  ---@param col integer
  local function edit(name, line, col)
    vim.cmd.edit(root .. "/" .. name)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
    vim.api.nvim_win_set_cursor(0, { 1, col })
  end

  before_each(function()
    cwd = vim.fn.getcwd()
    root = vim.fn.tempname()
    vim.fn.mkdir(root .. "/sub/dir", "p")
    vim.fn.writefile({}, root .. "/sub/target.txt")
    root = assert(vim.uv.fs_realpath(root))
  end)

  after_each(function()
    vim.cmd("silent! %bwipeout!")
    vim.fn.chdir(cwd)
    vim.fn.delete(root, "rf")
  end)

  it("returns a URL with no opener override", function()
    edit("notes.md", "see [docs](https://example.com/a?b=1). here", 6)
    local target, opts = links.under_cursor()
    assert.equal("https://example.com/a?b=1", target)
    assert.is_nil(opts)
  end)

  it("keeps parentheses that belong to the URL", function()
    assert.equal("https://en.wikipedia.org/wiki/Bloom_(app)", links.url("https://en.wikipedia.org/wiki/Bloom_(app)"))
  end)

  it("resolves a file relative to the buffer's directory, opened in Bloom", function()
    edit("sub/notes.md", "open target.txt:12 now", 7)
    local target, opts = links.under_cursor()
    assert.equal(root .. "/sub/target.txt", target)
    assert.same({ "open", "-a", "Bloom" }, (opts or {}).cmd)
  end)

  it("resolves a directory relative to the cwd", function()
    vim.fn.chdir(root)
    edit("notes.md", "look in sub/dir", 10)
    assert.equal(root .. "/sub/dir/", (links.under_cursor()))
  end)

  it("returns nil for text that names nothing on disk", function()
    edit("notes.md", "nothing here", 2)
    assert.is_nil(links.under_cursor())
  end)
end)

describe("links._span", function()
  it("picks the occurrence of the text that covers the column", function()
    assert.same({ 8, 13 }, { links._span("a.lua b a.lua", 9, "a.lua") })
  end)

  it("returns nil when the column sits outside every occurrence", function()
    assert.is_nil(links._span("see  a.lua", 3, "a.lua"))
  end)
end)
