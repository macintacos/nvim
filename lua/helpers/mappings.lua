local M = {}

---Convenience function that wraps the given string with `<Cmd>` and `<CR>`.
---@param command string The command to wrap.
---@return string wrapped The command surrounded by `<Cmd>...<CR>`.
function M.Cmd(command)
  return "<Cmd>" .. command .. "<CR>"
end

---@class helpers.mappings.Opts
---@field buffer? integer|boolean         Buffer-local mapping. `true` = current buffer, integer = specific buffer.
---@field silent? boolean                 Suppress command-line output.
---@field remap? boolean                  Allow recursive remapping (default false, matching `vim.keymap.set`).
---@field expr? boolean                   Evaluate `rhs` as a Vim expression.
---@field nowait? boolean                 Don't wait for more keys after a match.
---@field script? boolean                 Remap only script-local mappings.
---@field unique? boolean                 Fail if a mapping already exists for `lhs`.
---@field replace_keycodes? boolean       For expr mappings, replace keycodes in the returned string (default true when `expr` is true).

---Create a key mapping with the description, mode, lhs, and rhs required up front.
---
---This is a thin, behavior-preserving wrapper over `vim.keymap.set`. Its only
---purpose is readability: putting `desc` first makes the mapping's intent
---visible at a glance, instead of being buried after a multi-line `rhs`.
---
---All four leading parameters are required positional arguments; omitting any
---of them raises a Lua error at the call site. Every field of
---`vim.keymap.set`'s `{opts}` except `desc` is supported via the trailing
---`opts` table.
---
---@param desc string                    Human-readable description (shown in which-key / `:verbose map`).
---@param mode string|string[]           Mode(s) the mapping applies to — e.g. `"n"`, `{ "n", "x" }`, `"i"`.
---@param lhs string                     Left-hand side — the key sequence to press.
---@param rhs string|function            Right-hand side — a Vim keystroke string or a Lua callback.
---@param opts? helpers.mappings.Opts    Remaining `vim.keymap.set` options.
function M.map(desc, mode, lhs, rhs, opts)
  opts = opts or {}
  vim.keymap.set(mode, lhs, rhs, {
    desc = desc,
    buffer = opts.buffer,
    silent = opts.silent,
    remap = opts.remap,
    expr = opts.expr,
    nowait = opts.nowait,
    script = opts.script,
    unique = opts.unique,
    replace_keycodes = opts.replace_keycodes,
  })
end

return M
