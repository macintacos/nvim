local inline = require("plugins.go-folds.inline")

---The constructs of a Go file holding `lines`, as `{ first, last, text }` triples.
---@param lines string[]
---@param opts? go-folds.inline.Opts
---@return [integer, integer, string][]
local function constructs(lines, opts)
  local root = assert(vim.treesitter.get_string_parser(table.concat(lines, "\n"), "go"):parse())[1]:root()
  local found = inline.constructs(root, function(row)
    return lines[row + 1]
  end, opts or { width = 100, tabstop = 4 })
  return vim.tbl_map(function(construct)
    return { construct.first, construct.last, construct.text }
  end, found)
end

---`body` wrapped in a function, so statements parse where Go allows them.
---@param body string[]
---@return string[]
local function in_func(body)
  local lines = { "package p", "func f(err error, x any) int {" }
  for _, line in ipairs(body) do
    lines[#lines + 1] = "\t" .. line
  end
  vim.list_extend(lines, { "\tx = 1", "\treturn 0", "}" })
  return lines
end

describe("constructs", function()
  for _, case in ipairs({
    { "an if that returns", { "if err != nil {", "\treturn 1", "}" }, "    if err != nil { return 1 }" },
    { "an if that panics", { "if err != nil {", "\tpanic(err)", "}" }, "    if err != nil { panic(err) }" },
    { "an if holding any one statement", { "if x == nil {", "\tx = 2", "}" }, "    if x == nil { x = 2 }" },
    {
      "an if with an initializer",
      { "if e := g(); e != nil {", "\treturn 1", "}" },
      "    if e := g(); e != nil { return 1 }",
    },
    {
      "a function literal that returns",
      { "x = func() int {", "\treturn 1", "}" },
      "    x = func() int { return 1 }",
    },
  }) do
    it(("joins %s onto one line"):format(case[1]), function()
      assert.same({ { 2, 4, case[3] } }, constructs(in_func(case[2])))
    end)
  end

  it("joins a function and a method that only return", function()
    assert.same(
      {
        { 1, 3, "func double(n int) int { return n * 2 }" },
        { 4, 6, "func (u User) Name() string { return u.name }" },
      },
      constructs({
        "package p",
        "func double(n int) int {",
        "\treturn n * 2",
        "}",
        "func (u User) Name() string {",
        "\treturn u.name",
        "}",
      })
    )
  end)

  it("joins each one-statement case and default clause", function()
    assert.same(
      {
        { 3, 4, '    case "a": return 1' },
        { 5, 6, "    default: return 2" },
        { 9, 10, "    case string: return 3" },
      },
      constructs(in_func({
        "switch x {",
        'case "a":',
        "\treturn 1",
        "default:",
        "\treturn 2",
        "}",
        "switch x.(type) {",
        "case string:",
        "\treturn 3",
        "}",
      }))
    )
  end)

  it("draws the indentation at the buffer's tab width", function()
    local found = constructs(in_func({ "if err != nil {", "\treturn 1", "}" }), { width = 100, tabstop = 2 })
    assert.same({ { 2, 4, "  if err != nil { return 1 }" } }, found)
  end)

  for _, case in ipairs({
    { "an if with an else", { "if err != nil {", "\treturn 1", "} else {", "\tx = 2", "}" } },
    { "a block holding a comment", { "if err != nil {", "\t// why", "\treturn 1", "}" } },
    { "a statement with a trailing comment", { "if err != nil {", "\treturn 1 // why", "}" } },
    { "a block of two statements", { "if err != nil {", "\tx = 2", "\treturn 1", "}" } },
    { "an empty block", { "if err != nil {", "}" } },
    { "a header spanning lines", { "if err != nil &&", "\tx == nil {", "\treturn 1", "}" } },
    { "a statement spanning lines", { "if err != nil {", "\treturn g(", "\t\t1)", "}" } },
    { "a function literal that does not return", { "x = func() {", "\tpanic(err)", "}" } },
    { "a case of two statements", { "switch x {", 'case "a":', "\tx = 2", "\treturn 1", "}" } },
    { "a case already on one line", { "switch x {", 'case "a": return 1', "}" } },
    { "a case holding a comment", { "switch x {", 'case "a":', "\t// why", "\treturn 1", "}" } },
  }) do
    it(("leaves %s expanded"):format(case[1]), function()
      assert.same({}, constructs(in_func(case[2])))
    end)
  end

  it("leaves a function that does more than return expanded", function()
    assert.same({}, constructs({ "package p", "func f() {", "\tpanic(1)", "}" }))
  end)

  it("leaves a construct expanded when its one line would overrun the width", function()
    local lines = in_func({ "if err != nil {", "\treturn 1", "}" })
    assert.same({ { 2, 4, "    if err != nil { return 1 }" } }, constructs(lines, { width = 30, tabstop = 4 }))
    assert.same({}, constructs(lines, { width = 29, tabstop = 4 }))
  end)
end)

describe("widen", function()
  it("stretches a block's range over its closing brace", function()
    local ranges = inline.widen({ { startLine = 0, endLine = 9 }, { startLine = 2, endLine = 3 } }, {
      { first = 2, last = 4 },
    })
    table.sort(ranges, function(a, b)
      return a.startLine < b.startLine
    end)
    assert.same({ { startLine = 0, endLine = 9 }, { startLine = 2, endLine = 4 } }, ranges)
  end)

  it("adds a range for a construct the server reported none for", function()
    assert.same({ { startLine = 2, endLine = 3 } }, inline.widen({}, { { first = 2, last = 3 } }))
  end)
end)
