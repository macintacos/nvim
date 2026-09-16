-- Custom blink.pairs rules for markdown emphasis, plus the symmetric-delimiter
-- parity predicate the default rules share. plugin/blink.lua wires both into
-- blink.pairs' mapping schema.

local M = {}

local md = { "markdown", "markdown_inline" }

---Whether the cursor sits outside an inline code span, where emphasis is literal.
---@param ctx blink.pairs.Context
---@return boolean
function M.outside_code_span(ctx)
  local _, backticks = ctx:text_before_cursor():gsub("`", "")
  return backticks % 2 == 0
end

---Whether `char` occurs an even number of times in `before` — the "no span is
---open, open a fresh pair" verdict.
---@param char string
---@param before string
---@return boolean
local function even_parity(char, before)
  local _, count = before:gsub(vim.pesc(char), "")
  return count % 2 == 0
end

---Build an `open_or_close` predicate for a symmetric delimiter. blink.pairs'
---Rust parser tracks a stack of distinct opening/closing tokens, so symmetric
---delimiters (` " $ ' _ *) never appear on it and its "is this delimiter
---unmatched" lookup always answers nil — typing ` at the end of `foo would
---open a fresh pair instead of closing the span. Counting delimiters to the
---left gives the answer the parser can't: an odd count means the cursor sits
---inside an unclosed span, so the keypress closes it.
---@param char string The delimiter, which is both the opening and closing text
---@return fun(ctx: blink.pairs.Context): boolean open Whether to insert a pair
function M.balanced(char)
  return function(ctx)
    -- A closer already sits under the cursor; let blink.pairs jump over it
    if ctx:is_after_cursor(char) then
      return true
    end
    return even_parity(char, ctx:text_before_cursor():gsub("\\.", ""))
  end
end

---`balanced` for markdown emphasis: delimiters inside `...` inline code spans
---are literal text, not emphasis, so they must not sway the parity.
local function balanced_md(char)
  return function(ctx)
    if ctx:is_after_cursor(char) then
      return true
    end
    local before = ctx:text_before_cursor():gsub("`[^`]*`", ""):gsub("\\.", "")
    return even_parity(char, before)
  end
end

-- blink.pairs ships `*` and `_` rules for typst only, and no `~` rule at all,
-- so markdown emphasis delimiters never pair. The markdown rules below reuse
-- the parity predicate — which is also what makes `**bold**` and `~~strike~~`
-- work: the second keypress lands on an existing closer and shifts past it.
M.md_rules = {
  ["*"] = {
    "*",
    languages = md,
    enter = false,
    space = false,
    when = M.outside_code_span,
    open_or_close = balanced_md("*"),
  },
  ["~"] = {
    "~",
    languages = md,
    enter = false,
    space = false,
    when = M.outside_code_span,
    open_or_close = balanced_md("~"),
  },
  ["_"] = {
    "_",
    languages = md,
    enter = false,
    space = false,
    -- markdown reads `foo_bar` as a literal underscore, not emphasis, so only
    -- pair at a word boundary -- unless a closer is already under the cursor,
    -- which is how `_em_` closes its own span.
    when = function(ctx)
      return M.outside_code_span(ctx) and (ctx:is_after_cursor("_") or not ctx:text_before_cursor():match("%w$"))
    end,
    open_or_close = balanced_md("_"),
  },
}

---`<C-g>U`-guarded cursor shifts, mirroring blink.pairs' ops.shift_keycode.
local function md_shift(amount)
  local non_undo = vim.api.nvim_get_mode().mode ~= "c" and "<C-g>U" or ""
  if amount > 0 then
    return string.rep(non_undo .. "<Right>", amount)
  end
  return string.rep(non_undo .. "<Left>", -amount)
end

---Wrap blink.pairs' ops.open_or_close_pair: markdown emphasis rules decide
---locally, because the engine's Rust-parser stage misreads intraword `_`
---inside code spans (e.g. `non_top100`) as an unterminated italic and closes
---instead of opening, overriding the parity verdict. Other rules pass through
---untouched.
---@param orig fun(ctx: blink.pairs.Context, key: string, rule: blink.pairs.Rule): string
---@return fun(ctx: blink.pairs.Context, key: string, rule: blink.pairs.Rule): string
function M.wrap_open_or_close(orig)
  local ours = {}
  for _, rule in pairs(M.md_rules) do
    ours[rule.open_or_close] = true
  end
  return function(ctx, key, rule)
    if not ours[rule.open_or_close] then
      return orig(ctx, key, rule)
    end
    if ctx.is_escaped then
      return key
    end
    local pair = rule.opening
    assert(pair == rule.closing, "md emphasis delimiters are symmetric")
    if ctx:is_after_cursor(pair) then
      return md_shift(#pair)
    end
    return pair .. pair .. md_shift(-#pair)
  end
end

return M
