local M = {}

local ns = vim.api.nvim_create_namespace("helpers.hover")

local FOCUS_ID = "textDocument/hover"

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
---@param results table<integer, { err?: lsp.ResponseError, result?: lsp.Hover }>
---@return string[]
local function hover_lines(results)
  local lines = {}
  for _, response in pairs(results) do
    local contents = response.result and vim.lsp.util.convert_input_to_markdown_lines(response.result.contents)
    if contents and #contents > 0 then
      lines[#lines + 1] = "---"
      vim.list_extend(lines, contents)
    end
  end
  return lines
end

---Show LSP hover docs for the cursor, with the cursor line's diagnostics merged above them.
---Without diagnostics this is plain `vim.lsp.buf.hover`.
---@param config vim.lsp.util.open_floating_preview.Opts
function M.hover(config)
  local existing = vim.b.lsp_floating_preview
  if existing and vim.api.nvim_win_is_valid(existing) and vim.w[existing][FOCUS_ID] then
    vim.api.nvim_set_current_win(existing)
    return
  end

  local icons = vim.tbl_get(vim.diagnostic.config() or {}, "signs", "text") or { "E", "W", "I", "H" }
  local lines, highlights = format_diagnostics(cursor_line_diagnostics(), icons)
  if #lines == 0 then
    return vim.lsp.buf.hover(config)
  end

  local bufnr, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local cursor = vim.api.nvim_win_get_cursor(win)

  ---@param docs string[]
  local function open(docs)
    local float_buf = vim.lsp.util.open_floating_preview(
      vim.list_extend(vim.list_extend({}, lines), docs),
      "markdown",
      vim.tbl_extend("force", config, { focus_id = FOCUS_ID })
    )
    for row, group in ipairs(highlights) do
      vim.api.nvim_buf_set_extmark(float_buf, ns, row - 1, 0, { line_hl_group = group })
    end
  end

  if #vim.lsp.get_clients({ bufnr = bufnr, method = FOCUS_ID }) == 0 then
    return open({})
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
