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
  local parsed = util.parse_query(query)
  local pending = 0
  local cancelled = false
  local processes = {}

  -- Intermediate raw result buffers — filtering happens in on_done
  local raw_files = {} ---@type string[]
  local raw_headings = {} ---@type { path: string, lnum: number, text: string }[]
  local raw_content = {} ---@type { path: string, lnum: number, col: number, text: string }[]

  local function on_done()
    pending = pending - 1
    if pending ~= 0 or cancelled then
      return
    end

    local items = {}

    -- Build a set of matched file paths (for # mode cross-filtering)
    local matched_paths = nil
    if parsed.has_hash then
      matched_paths = {}
      for _, abs_path in ipairs(raw_files) do
        local filename = vim.fn.fnamemodify(abs_path, ":t")
        if parsed.file_query == "" or util.is_smart_exact(parsed.file_query, filename) then
          matched_paths[abs_path] = true
        end
      end
    end

    -- File items
    local file_count = 0
    for _, abs_path in ipairs(raw_files) do
      if file_count >= M.MAX_RESULTS_PER_TYPE then
        break
      end
      if not parsed.has_hash or matched_paths[abs_path] then
        items[#items + 1] = file_item(abs_path, buf_dir, parsed.file_query)
        file_count = file_count + 1
      end
    end

    -- Heading items
    local heading_count = 0
    for _, h in ipairs(raw_headings) do
      if heading_count >= M.MAX_RESULTS_PER_TYPE then
        break
      end
      if parsed.has_hash then
        -- Only include headings from files that matched file_query
        if matched_paths[h.path] then
          local hq = parsed.heading_query
          if hq == "" or util.is_smart_exact(hq, h.text) then
            local item = heading_item(h.path, buf_dir, h.lnum, h.text, hq)
            -- In # mode, boost headings above file results
            item.score_offset = item.score_offset + 200
            items[#items + 1] = item
            heading_count = heading_count + 1
          end
        end
      else
        -- Without #: only include headings that match the query text
        if query ~= "" and util.is_smart_exact(query, h.text) then
          items[#items + 1] = heading_item(h.path, buf_dir, h.lnum, h.text, query)
          heading_count = heading_count + 1
        end
      end
    end

    -- Content items
    local content_count = 0
    for _, c in ipairs(raw_content) do
      if content_count >= M.MAX_RESULTS_PER_TYPE then
        break
      end
      items[#items + 1] = content_item(c.path, buf_dir, c.lnum, c.col, c.text, query)
      content_count = content_count + 1
    end

    vim.schedule(function()
      callback({
        items = items,
        is_incomplete_forward = true,
        is_incomplete_backward = true,
      })
    end)
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
    for line in result.stdout:gmatch("[^\n]+") do
      raw_files[#raw_files + 1] = line
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
      for line in result.stdout:gmatch("[^\n]+") do
        -- Format: path:line_nr:heading_line
        local path, lnum, text = line:match("^(.+):(%d+):(.+)$")
        if path and lnum and text then
          local heading = text:match("^#+%s+(.+)$")
          if heading then
            raw_headings[#raw_headings + 1] = { path = path, lnum = tonumber(lnum), text = heading }
          end
        end
      end
      on_done()
    end
  )

  -- 3. Content search (only when query is 2+ chars and no # syntax)
  if not parsed.has_hash and #query >= 2 then
    pending = pending + 1
    processes[#processes + 1] = vim.system(
      { "rg", "--no-heading", "-n", "--column", "-S", "--max-count", "100", query, root },
      { text = true },
      function(result)
        if cancelled or result.code ~= 0 then
          on_done()
          return
        end
        for line in result.stdout:gmatch("[^\n]+") do
          -- Format: path:line_nr:col:matched_text
          local path, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")
          if path and lnum and col then
            raw_content[#raw_content + 1] =
              { path = path, lnum = tonumber(lnum), col = tonumber(col), text = text or "" }
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
