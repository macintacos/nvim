local unmatched = require("plugins.blink-pairs.unmatched")

---A scratch markdown buffer holding `lines`.
---@param lines string[]
---@return integer
local function markdown(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "markdown"
  return buf
end

---Unmatched delimiter positions across every line of a markdown buffer holding `lines`.
---@param lines string[]
---@return blink_pairs.Pos[]
local function positions(lines)
  return unmatched.positions(markdown(lines), 0, #lines)
end

describe("unmatched delimiter positions", function()
  it("reports the last delimiter of an odd run in a paragraph", function()
    assert.same({ { 0, 17 } }, positions({ 'He said "hi" and "bye' }))
  end)

  it("matches a quote across a hard line break", function()
    assert.same({}, positions({ 'He said "hi', 'there" ok' }))
  end)

  it("counts each paragraph on its own", function()
    assert.same({ { 0, 2 }, { 2, 1 } }, positions({ 'a "b', "", 'c" d' }))
  end)

  it("tracks backticks and emphasis delimiters, in buffer order", function()
    assert.same({ { 0, 6 }, { 0, 12 }, { 0, 28 } }, positions({ "**bold* and `code and ~~gone~" }))
  end)

  for name, lines in pairs({
    ["inline code"] = { 'a `x"y` b' },
    ["a fenced code block"] = { "```lua", 'local s = "x', "```" },
    ["frontmatter"] = { "---", 'title: "x', "---", "", "body" },
    ["an escaped delimiter"] = { 'a \\" b' },
    ["a link URL"] = { "[a](http://x_y)" },
    ["an autolink"] = { "<https://x_y>" },
    ["inline HTML"] = { "<span title='a\"b'>x</span>" },
    ["an HTML comment"] = { 'a <!-- " --> b' },
  }) do
    it("does not count a delimiter inside " .. name, function()
      assert.same({}, positions(lines))
    end)
  end

  it("reports only the rows in range", function()
    assert.same({ { 2, 2 } }, unmatched.positions(markdown({ 'a "b', "", 'c "d' }), 2, 3))
  end)

  it("counts the whole paragraph when only part of it is in range", function()
    assert.same({ { 1, 5 } }, unmatched.positions(markdown({ 'a "b', 'c" d "e' }), 1, 2))
  end)
end)

describe("open span at a position", function()
  it("is open when an earlier line of the paragraph leaves one unclosed", function()
    assert.is_true(unmatched.span_open(markdown({ 'He said "hi', "there " }), 1, 6, '"'))
  end)

  it("is closed when every span before it is matched or inside code", function()
    assert.is_false(unmatched.span_open(markdown({ 'a "b" `c"d` ' }), 0, 12, '"'))
  end)

  it("is unknown inside a fenced code block", function()
    assert.is_nil(unmatched.span_open(markdown({ "```lua", 'x = "', "```" }), 1, 5, '"'))
  end)

  it("is unknown inside a code span", function()
    assert.is_nil(unmatched.span_open(markdown({ 'a `x"y` b' }), 0, 4, '"'))
  end)
end)
