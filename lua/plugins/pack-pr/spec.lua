local M = {}

---Build a `vim.pack` spec literal for `src`, tracking `branch`.
---A nil/empty branch yields the bare-string form (track the default branch); a
---branch yields a single-line table form pinned to it via the `version` field.
---@param src string The plugin's git source URL.
---@param branch string? The branch to track, or nil/"" to reset to default.
---@return string literal A Lua spec literal: `"<src>"` or `{ src = "<src>", version = "<branch>" }`.
function M.build_spec(src, branch)
  if branch == nil or branch == "" then
    return string.format("%q", src)
  end
  return string.format("{ src = %q, version = %q }", src, branch)
end

---Rewrite the `vim.pack` spec entry referencing `src` so it tracks `branch`
---(or, when `branch` is nil, reset it to the bare-string default-branch form).
---Handles the two spec forms this config uses: a bare quoted string and a
---single-line `{ src = ..., version = ... }` table left by a prior switch. Only
---the first match is rewritten; unquoted mentions (e.g. header comments) never
---match because the pattern requires the quoted source.
---@param content string The current spec file contents.
---@param src string The plugin's git source URL to locate.
---@param branch string? The branch to track, or nil to reset to default.
---@return string content The rewritten contents (unchanged when no match).
---@return boolean changed Whether the contents actually changed.
function M.rewrite(content, src, branch)
  local replacement = M.build_spec(src, branch):gsub("%%", "%%%%")
  local esc = vim.pesc(src)
  -- Single-line table entry: { ... src = "<src>" ... } with no nested braces.
  local table_pat = "{[^{}]-src%s*=%s*[\"']" .. esc .. "[\"'][^{}]-}"
  if content:find(table_pat) then
    local new = content:gsub(table_pat, replacement, 1)
    return new, new ~= content
  end
  -- Bare quoted string: "<src>" or '<src>'.
  local bare_pat = "[\"']" .. esc .. "[\"']"
  if content:find(bare_pat) then
    local new = content:gsub(bare_pat, replacement, 1)
    return new, new ~= content
  end
  return content, false
end

return M
