-- Custom blink.pairs rules for markdown emphasis, the symmetric-delimiter
-- parity predicate the default rules share, and the highlight on unmatched
-- markdown delimiters. plugin/blink.lua wires the rules into blink.pairs'
-- mapping schema and calls setup().

local unmatched = require("plugins.blink-pairs.unmatched")

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
---inside an unclosed span, so the keypress closes it. Markdown prose counts
---across the whole paragraph, as the unmatched highlight does; everywhere
---else counts the line.
---@param char string The delimiter, which is both the opening and closing text
---@return fun(ctx: blink.pairs.Context): boolean open Whether to insert a pair
function M.balanced(char)
  ---@param ctx blink.pairs.Context
  return function(ctx)
    -- A closer already sits under the cursor; let blink.pairs jump over it
    if ctx:is_after_cursor(char) then
      return true
    end
    local open = unmatched.span_open(ctx.bufnr, ctx.cursor.row - 1, ctx.cursor.col, char)
    if open == nil then
      return even_parity(char, ctx:text_before_cursor():gsub("\\.", ""))
    end
    return not open
  end
end

---Narrow a stock rule's `when` so `'` and `$` never pair in markdown, where
---apostrophes and prices leave most of them unpaired.
---@param char string The rule's delimiter
---@param when? fun(ctx: blink.pairs.Context): boolean The rule's own `when`
---@return (fun(ctx: blink.pairs.Context): boolean)?
function M.when(char, when)
  if char ~= "'" and char ~= "$" then
    return when
  end
  return function(ctx)
    return not ctx.ts:is_language(md) and (when == nil or when(ctx))
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
    open_or_close = M.balanced("*"),
  },
  ["~"] = {
    "~",
    languages = md,
    enter = false,
    space = false,
    when = M.outside_code_span,
    open_or_close = M.balanced("~"),
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
    open_or_close = M.balanced("_"),
  },
}

-- blink.pairs pairs `<>` only for generics in a few languages; markdown wants
-- it for inline HTML and autolinks.
M.md_tag_rules = {
  ["<"] = { "<", ">", languages = md, enter = false, space = false },
  -- The `<` pair already left a `>` under the cursor, so `<!--` closes with
  -- `--` instead of the stock rule's `-->`, which would stack a second `>`.
  ["!"] = {
    "<!--",
    "--",
    languages = md,
    when = function(ctx)
      return ctx:is_after_cursor(">")
    end,
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

---Wrap blink.pairs' ops.open_or_close_pair: in markdown, the delimiters the
---unmatched highlight tracks decide locally from the paragraph count. The
---engine's Rust-parser stage would otherwise override it, as when it misreads
---intraword `_` inside code spans (e.g. `non_top100`) as an unterminated
---italic and closes instead of opening. Other rules pass through untouched.
---@param orig fun(ctx: blink.pairs.Context, key: string, rule: blink.pairs.Rule): string
---@return fun(ctx: blink.pairs.Context, key: string, rule: blink.pairs.Rule): string
function M.wrap_open_or_close(orig)
  return function(ctx, key, rule)
    if not (unmatched.tracks(rule.opening) and ctx.ts:is_language(md)) then
      return orig(ctx, key, rule)
    end
    if ctx.is_escaped or not rule.open_or_close(ctx) then
      return key
    end
    local pair = rule.opening
    assert(pair == rule.closing, "markdown delimiters are symmetric")
    if ctx:is_after_cursor(pair) then
      return md_shift(#pair)
    end
    return pair .. pair .. md_shift(-#pair)
  end
end

---Color the unmatched delimiters on rows `top` to `bot` of `buf`.
---@param ns integer
---@param buf integer
---@param top integer 0-based
---@param bot integer 0-based, exclusive
local function highlight(ns, buf, top, bot)
  vim.api.nvim_buf_clear_namespace(buf, ns, top, bot)
  for _, pos in ipairs(unmatched.positions(buf, top, bot)) do
    vim.api.nvim_buf_set_extmark(buf, ns, pos[1], pos[2], {
      end_col = pos[2] + 1,
      hl_group = "BlinkPairsUnmatched",
      priority = vim.hl.priorities.user,
    })
  end
end

---Keep the unmatched delimiters of every markdown buffer highlighted, on the
---rows its windows show.
function M.setup()
  local ns = vim.api.nvim_create_namespace("blink_pairs_unmatched")
  ---@type table<integer, string>
  local drawn = {}
  -- Recolors a window's rows when it shows new ones (scroll, resize, fold) or
  -- its buffer changes. Skips nofile buffers: LSP hover floats are markdown
  -- too, but hold generated docs.
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, win, buf, top, bot)
      if vim.bo[buf].filetype ~= "markdown" or vim.bo[buf].buftype == "nofile" then
        return false
      end
      local view = table.concat({ buf, vim.api.nvim_buf_get_changedtick(buf), top, bot }, ":")
      if drawn[win] ~= view then
        drawn[win] = view
        highlight(ns, buf, top, bot + 1)
      end
      return false
    end,
  })
end

return M
