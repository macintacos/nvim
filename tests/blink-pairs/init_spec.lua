local md_pairs = require("plugins.blink-pairs")

-- The rules under test read only the two slice/compare methods a Context
-- provides. blink.pairs builds Contexts through its Rust-backed parser path,
-- which these specs stay out of, so make_ctx mirrors those methods' semantics
-- verbatim from blink.pairs' context/init.lua.
---A Context positioned at 0-based column `col` on `line`.
---@param is_escaped? boolean
local function make_ctx(line, col, is_escaped)
  local ctx = { line = line, cursor = { row = 1, col = col }, is_escaped = is_escaped or false }
  function ctx:text_before_cursor(chars)
    return self.line:sub(chars and (self.cursor.col - chars + 1) or 1, self.cursor.col)
  end
  function ctx:is_after_cursor(text)
    return self.line:sub(self.cursor.col + 1, self.cursor.col + #text) == text
  end
  return ctx
end

describe("markdown emphasis pairing", function()
  local rules = md_pairs.md_rules

  it("opens a pair at end of line even when code spans hold an odd number of underscores", function()
    local line = "check `ai_native_customer` against `non_top100` labels "
    assert.is_true(rules["_"].open_or_close(make_ctx(line, #line)))
  end)

  it("opens a pair at end of line even when code spans hold an odd number of tildes", function()
    local line = "range `~1` to "
    assert.is_true(rules["~"].open_or_close(make_ctx(line, #line)))
  end)

  it("closes the span when an emphasis delimiter is already open", function()
    local line = "make _this emphasized "
    assert.is_false(rules["_"].open_or_close(make_ctx(line, #line)))
  end)

  it("shifts past a closer already under the cursor", function()
    assert.is_true(rules["_"].open_or_close(make_ctx("make _em_", 8)))
  end)

  it("does not count escaped delimiters", function()
    local line = "an \\_literal and "
    assert.is_true(rules["_"].open_or_close(make_ctx(line, #line)))
  end)

  it("does not pair inside an unclosed code span", function()
    assert.is_false(rules["_"].when(make_ctx("see `foo_bar", #"see `foo_bar")))
  end)

  it("does not pair mid-word", function()
    assert.is_false(rules["_"].when(make_ctx("snake_case", #"snake_case")))
  end)
end)

describe("symmetric-delimiter parity", function()
  it("opens on an even count to the left and closes on an odd one", function()
    local backtick = md_pairs.balanced("`")
    assert.is_true(backtick(make_ctx("a `x` tail ", #"a `x` tail ")))
    assert.is_false(backtick(make_ctx("a `code span", #"a `code span")))
  end)
end)

describe("open_or_close override for markdown emphasis", function()
  -- rule.opening/opening mirror what blink.pairs' rule_from_def builds; the
  -- open_or_close closure must be the module's own, since the override
  -- identifies its rules by that closure's identity.
  local function md_rule(char)
    return { opening = char, closing = char, open_or_close = md_pairs.md_rules[char].open_or_close }
  end

  local wrapped = md_pairs.wrap_open_or_close(function(_ctx, key, _rule)
    return "ORIG:" .. key
  end)

  it("emits the pair keystring for its own rules, without consulting the parser", function()
    assert.equal("__<C-g>U<Left>", wrapped(make_ctx("any line ", 8), "_", md_rule("_")))
  end)

  it("shifts past a closer already under the cursor", function()
    assert.equal("<C-g>U<Right>", wrapped(make_ctx("make _em_", 8), "_", md_rule("_")))
  end)

  it("leaves escaped delimiters alone", function()
    assert.equal("_", wrapped(make_ctx("a \\_ b ", 7, true), "_", md_rule("_")))
  end)

  it("passes other rules through to the wrapped original", function()
    local rule = {
      opening = "`",
      closing = "`",
      open_or_close = function()
        return true
      end,
    }
    assert.equal("ORIG:`", wrapped(make_ctx("a `x` ", 6), "`", rule))
  end)
end)
