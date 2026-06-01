local M = {}

local map = require("helpers.mappings").map

---Extract the git target (commit SHA or tag) encoded on a single buffer line.
---Mirrors the line patterns used by vim.pack's built-in LSP hover handler.
---@param line string A line from the nvim-pack confirmation buffer.
---@return string? target The commit SHA or tag name, or nil if the line has none.
---@return ("commit"|"tag")? kind What `target` represents, or nil.
local function parse_target(line)
  local commit = line:match("^[<>] (%x+) │") or line:match("^Revision.*:%s+(%x+)")
  if commit then
    return commit, "commit"
  end
  local tag = line:match("^• (.+)$")
  if tag then
    return tag, "tag"
  end
  return nil, nil
end

---Walk backward from `lnum` to the nearest `Source:` line in the same section.
---Reads the buffer text rather than vim.pack.get so it also works for plugins
---marked "(not active)".
---@param lines string[] All lines of the confirmation buffer (1-indexed).
---@param lnum integer The 1-indexed line to start searching upward from.
---@return string? src The plugin's source URL, or nil if none precedes `lnum`.
local function find_source(lines, lnum)
  for i = lnum, 1, -1 do
    local src = lines[i]:match("^Source:%s+(.+)$")
    if src then
      return src
    end
  end
  return nil
end

---Build the remote URL for a commit or tag from a git source URL.
---Assumes a GitHub-style host (every source in this config is github.com).
---@param src string The plugin's git source URL.
---@param target string The commit SHA or tag name.
---@param kind "commit"|"tag" What `target` represents.
---@return string url The remote URL to open.
local function build_url(src, target, kind)
  local base = src:gsub("%.git$", "")
  if kind == "tag" then
    return base .. "/releases/tag/" .. target
  end
  return base .. "/commit/" .. target
end

---Resolve the commit/tag under the cursor and open it in the browser.
---No-ops silently on lines that hold neither (headers, blanks, Source lines).
local function open_at_cursor()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local lnum = vim.fn.line(".")
  local target, kind = parse_target(lines[lnum])
  if not target then
    return
  end
  local src = find_source(lines, lnum)
  if not src then
    vim.notify("pack-tweaks: no Source line for this section", vim.log.levels.WARN)
    return
  end
  vim.ui.open(build_url(src, target, kind))
end

---Attach the buffer-local <CR> keymap to a vim.pack confirmation buffer.
---@param bufnr integer The confirmation buffer to map.
function M.attach(bufnr)
  map("Open commit/tag in remote", "n", "<CR>", open_at_cursor, { buffer = bufnr, silent = true })
end

-- Exposed for unit tests.
M._parse_target = parse_target
M._find_source = find_source
M._build_url = build_url

return M
