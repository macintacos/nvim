local M = {}

local ns = vim.api.nvim_create_namespace("helpers.hover")

local FOCUS_ID = "textDocument/hover"

local CHANGESET = "changeset"

---@type table<vim.diagnostic.Severity, string>
local SEVERITY_NAMES = { "Error", "Warn", "Info", "Hint" }

---Markdown lines for diagnostics, most severe first, and each line's highlight group.
---@param diagnostics vim.Diagnostic[]
---@param icons table<vim.diagnostic.Severity, string> Sign text per severity
---@return string[] lines
---@return string[] highlights Highlight group for the line at the same index
local function format_diagnostics(diagnostics, icons)
  local sorted = vim.deepcopy(diagnostics)
  table.sort(sorted, function(a, b)
    if a.severity ~= b.severity then
      return a.severity < b.severity
    end
    return a.col < b.col
  end)

  local lines, highlights = {}, {}
  for _, diagnostic in ipairs(sorted) do
    -- Blank lines would be collapsed by the float's markdown normalizing, shifting
    -- every later row out from under its highlight.
    local message = vim.split(diagnostic.message, "\n", { trimempty = true })
    if diagnostic.source and message[1] then
      message[1] = message[1] .. " (" .. diagnostic.source .. ")"
    end
    for i, text in ipairs(message) do
      if text ~= "" then
        lines[#lines + 1] = (i == 1 and icons[diagnostic.severity] .. " " or "  ") .. text
        highlights[#highlights + 1] = "DiagnosticFloating" .. SEVERITY_NAMES[diagnostic.severity]
      end
    end
  end
  return lines, highlights
end
M._format_diagnostics = format_diagnostics

---Diagnostics covering the cursor line, matching `vim.diagnostic.open_float`'s line scope.
---@return vim.Diagnostic[]
local function cursor_line_diagnostics()
  if not vim.diagnostic.is_enabled({ bufnr = 0 }) then
    return {}
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  return vim.tbl_filter(function(d)
    return d.lnum <= row and row <= d.end_lnum and (d.lnum == d.end_lnum or row ~= d.end_lnum or d.end_col ~= 0)
  end, vim.diagnostic.get(0))
end

---Hover docs from every attached LSP client, as markdown lines.
---The `changeset` client's review comments come apart so they can lead the popup.
---@param results table<integer, { err: lsp.ResponseError?, result: lsp.Hover? }>
---@return string[] review Markdown lines from the changeset client
---@return string[] docs Every other client's docs, each preceded by a `---` rule
local function hover_lines(results)
  local review, docs = {}, {}
  for client_id, response in pairs(results) do
    local contents = response.result and vim.lsp.util.convert_input_to_markdown_lines(response.result.contents)
    if contents and #contents > 0 then
      local client = vim.lsp.get_client_by_id(client_id)
      if client and client.name == CHANGESET then
        vim.list_extend(review, contents)
      else
        docs[#docs + 1] = "---"
        vim.list_extend(docs, contents)
      end
    end
  end
  return review, docs
end

---Show LSP hover docs for the cursor, with the cursor line's diagnostics merged above them
---and changeset's review comments above those.
---Without diagnostics or a changeset client this is plain `vim.lsp.buf.hover`.
---@param config vim.lsp.buf.hover.Opts
function M.hover(config)
  local existing = vim.b.lsp_floating_preview
  if existing and vim.api.nvim_win_is_valid(existing) and vim.w[existing][FOCUS_ID] then
    vim.api.nvim_set_current_win(existing)
    return
  end

  local bufnr, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local icons = vim.tbl_get(vim.diagnostic.config() or {}, "signs", "text") or { "E", "W", "I", "H" }
  local lines, highlights = format_diagnostics(cursor_line_diagnostics(), icons)
  if #lines == 0 and #vim.lsp.get_clients({ bufnr = bufnr, name = CHANGESET }) == 0 then
    return vim.lsp.buf.hover(config)
  end

  local cursor = vim.api.nvim_win_get_cursor(win)

  ---@param review string[]
  ---@param docs string[]
  local function open(review, docs)
    local content = vim.list_extend({}, review)
    if #review > 0 and #lines > 0 then
      content[#content + 1] = "---"
    end
    vim.list_extend(vim.list_extend(content, lines), docs)
    if #lines == 0 and #review == 0 then
      table.remove(content, 1)
    end
    if #content == 0 then
      return vim.notify("No information available", vim.log.levels.INFO)
    end
    local float_buf =
      vim.lsp.util.open_floating_preview(content, "markdown", vim.tbl_extend("force", config, { focus_id = FOCUS_ID }))
    -- Markdown normalizing can reflow the review lines, so find where the diagnostics landed.
    local first = #lines > 0 and vim.fn.index(vim.api.nvim_buf_get_lines(float_buf, 0, -1, false), lines[1]) or -1
    if first < 0 then
      return
    end
    for row, group in ipairs(highlights) do
      vim.api.nvim_buf_set_extmark(float_buf, ns, first + row - 1, 0, { line_hl_group = group })
    end
  end

  if #vim.lsp.get_clients({ bufnr = bufnr, method = FOCUS_ID }) == 0 then
    return open({}, {})
  end
  vim.lsp.buf_request_all(bufnr, FOCUS_ID, function(client)
    return vim.lsp.util.make_position_params(win, client.offset_encoding)
  end, function(results)
    -- The response is async: drop it if the user has since moved on.
    if vim.api.nvim_get_current_win() ~= win or not vim.deep_equal(vim.api.nvim_win_get_cursor(win), cursor) then
      return
    end
    open(hover_lines(results))
  end)
end

return M
