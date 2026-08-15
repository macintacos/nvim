---Recognising uv single-file scripts from buffer contents.
---
---A uv script is a Python file that carries its dependencies inline in a PEP 723
---`# /// script` block, and is usually launched through a `uv run` shebang rather
---than a .py extension.
local M = {}

---How far into a buffer to look for a metadata block. Matches the depth Neovim's
---own content-based filetype detection uses.
local SCAN_LINES = 100

---True when the buffer opens a PEP 723 `script` metadata block.
---Other block types (`# /// pyproject`) declare no dependencies, so they do not count.
---@param bufnr integer
---@return boolean
function M.has_inline_metadata(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, SCAN_LINES, false)) do
    if line:match("^%s*#%s*///%s*script%s*$") then
      return true
    end
  end
  return false
end

---True when the buffer's shebang launches the file through uv.
---Covers both `#!/usr/bin/env -S uv run --script` and a direct path to the binary;
---`uv` must be a whole path segment so unrelated words ending in "uv" do not match.
---@param bufnr integer
---@return boolean
function M.has_uv_shebang(bufnr)
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
  return first:match("^#!.*[/%s]uv%s+run") ~= nil
end

---Filetype for a path Neovim could not identify by name or extension.
---Returns nil for anything that is not a uv script, which leaves Neovim's own
---content-based detection to run as usual.
---@param _path string
---@param bufnr integer
---@return string|nil
function M.filetype(_path, bufnr)
  if M.has_uv_shebang(bufnr) or M.has_inline_metadata(bufnr) then
    return "python"
  end
  return nil
end

return M
