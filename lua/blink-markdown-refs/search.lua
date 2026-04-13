local util = require("blink-markdown-refs.util")

local M = {}

--- Maximum number of completion items returned per type (file, heading, content).
M.MAX_RESULTS_PER_TYPE = 5

local LABEL_MAX = 30

---Build a file completion item from an absolute path.
---@param abs_path string
---@param buf_dir string
---@param query string
---@return lsp.CompletionItem
local function file_item(abs_path, buf_dir, query)
  local rel = util.relative_path(buf_dir, abs_path)
  local filename = vim.fn.fnamemodify(abs_path, ":t")
  local exact = util.is_smart_exact(query, filename)
  return {
    label = util.truncate_left(rel, LABEL_MAX),
    kind = 17, -- File
    insertText = rel,
    filterText = filename .. " " .. rel,
    sortText = (exact and "0a_" or "1a_") .. filename:lower(),
    score_offset = exact and 300 or 100,
    data = { type = "file", path = abs_path, raw_path = rel, query = query },
  }
end

---Build a heading completion item.
---@param abs_path string
---@param buf_dir string
---@param line_nr number
---@param heading_text string
---@param query string
---@return lsp.CompletionItem
local function heading_item(abs_path, buf_dir, line_nr, heading_text, query)
  local rel = util.relative_path(buf_dir, abs_path)
  local filename = vim.fn.fnamemodify(abs_path, ":t")
  local anchor = util.heading_to_anchor(heading_text)
  local ref = rel .. "#" .. anchor
  local exact = util.is_smart_exact(query, heading_text)
  return {
    label = util.truncate_left(rel, LABEL_MAX),
    labelDetails = { description = heading_text },
    kind = 18, -- Reference
    insertText = ref,
    filterText = heading_text .. " " .. filename,
    sortText = (exact and "0b_" or "1b_") .. heading_text:lower(),
    score_offset = exact and 250 or 50,
    data = { type = "heading", path = abs_path, line = line_nr, raw_path = ref, query = query },
  }
end

---Build a content/line completion item.
---@param abs_path string
---@param buf_dir string
---@param line_nr number
---@param col number
---@param line_text string
---@param query string
---@return lsp.CompletionItem
local function content_item(abs_path, buf_dir, line_nr, col, line_text, query)
  local rel = util.relative_path(buf_dir, abs_path)
  local filename = vim.fn.fnamemodify(abs_path, ":t")
  local ref = rel .. ":" .. line_nr .. ":" .. col
  local truncated = #line_text > 60 and line_text:sub(1, 57) .. "..." or line_text
  local exact = util.is_smart_exact(query, line_text)
  return {
    label = util.truncate_left(ref, LABEL_MAX),
    labelDetails = { description = truncated },
    kind = 1, -- Text
    insertText = ref,
    filterText = line_text .. " " .. filename,
    sortText = (exact and "0c_" or "1c_") .. line_text:lower():sub(1, 40),
    score_offset = exact and 250 or 0,
    data = { type = "content", path = abs_path, line = line_nr, col = col, raw_path = ref, query = query },
  }
end

---Run a project-wide search and return completion items via callback.
---@param query string Text after the @ trigger
---@param root string Project root directory
---@param buf_dir string Current buffer's directory
---@param callback fun(response: table) blink.cmp callback
---@return fun() cancel Cancel function
function M.search(query, root, buf_dir, callback)
  local items = {}
  local pending = 0
  local cancelled = false
  local processes = {}

  local function on_done()
    pending = pending - 1
    if pending == 0 and not cancelled then
      vim.schedule(function()
        callback({
          items = items,
          is_incomplete_forward = true,
          is_incomplete_backward = true,
        })
      end)
    end
  end

  local function cancel()
    cancelled = true
    for _, proc in ipairs(processes) do
      if proc and proc.kill then
        pcall(proc.kill, proc, "sigterm")
      end
    end
  end

  -- 1. File search
  pending = pending + 1
  processes[#processes + 1] = vim.system({ "rg", "--files", root }, { text = true }, function(result)
    if cancelled or result.code ~= 0 then
      on_done()
      return
    end
    local count = 0
    for line in result.stdout:gmatch("[^\n]+") do
      if count >= M.MAX_RESULTS_PER_TYPE then
        break
      end
      items[#items + 1] = file_item(line, buf_dir, query)
      count = count + 1
    end
    on_done()
  end)

  -- 2. Heading search (all .md files)
  pending = pending + 1
  processes[#processes + 1] = vim.system(
    { "rg", "--no-heading", "-n", "^#{1,6}\\s", "--glob", "*.md", root },
    { text = true },
    function(result)
      if cancelled or result.code ~= 0 then
        on_done()
        return
      end
      local count = 0
      for line in result.stdout:gmatch("[^\n]+") do
        if count >= M.MAX_RESULTS_PER_TYPE then
          break
        end
        -- Format: path:line_nr:heading_line
        local path, lnum, text = line:match("^(.+):(%d+):(.+)$")
        if path and lnum and text then
          local heading = text:match("^#+%s+(.+)$")
          if heading then
            items[#items + 1] = heading_item(path, buf_dir, tonumber(lnum), heading, query)
            count = count + 1
          end
        end
      end
      on_done()
    end
  )

  -- 3. Content search (only when query is 2+ chars)
  if #query >= 2 then
    pending = pending + 1
    processes[#processes + 1] = vim.system(
      { "rg", "--no-heading", "-n", "--column", "-S", "--max-count", "100", query, root },
      { text = true },
      function(result)
        if cancelled or result.code ~= 0 then
          on_done()
          return
        end
        local count = 0
        for line in result.stdout:gmatch("[^\n]+") do
          if count >= M.MAX_RESULTS_PER_TYPE then
            break
          end
          -- Format: path:line_nr:col:matched_text
          local path, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
          if path and lnum and col then
            items[#items + 1] = content_item(path, buf_dir, tonumber(lnum), tonumber(col), text or "", query)
            count = count + 1
          end
        end
        on_done()
      end
    )
  end

  if pending == 0 then
    vim.schedule(function()
      callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    end)
  end

  return cancel
end

-- Exposed for testing only
M._file_item = file_item
M._heading_item = heading_item
M._content_item = content_item

return M
