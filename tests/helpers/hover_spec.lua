local hover = require("helpers.hover")
local severity = vim.diagnostic.severity

local icons = { [severity.ERROR] = "E", [severity.WARN] = "W", [severity.INFO] = "I", [severity.HINT] = "H" }

---@param lnum integer
---@param col integer
---@param sev vim.diagnostic.Severity
---@param message string
---@return vim.Diagnostic
local function diag(lnum, col, sev, message)
  return { lnum = lnum, col = col, end_lnum = lnum, end_col = col + 1, severity = sev, message = message }
end

describe("hover._format_diagnostics", function()
  it("lists every diagnostic, most severe first, then by column", function()
    local lines, highlights = hover._format_diagnostics({
      diag(0, 9, severity.WARN, "late warning"),
      diag(0, 1, severity.WARN, "early warning"),
      diag(0, 5, severity.ERROR, "error"),
    }, icons)
    assert.same({ "E error", "W early warning", "W late warning" }, lines)
    assert.same({ "DiagnosticFloatingError", "DiagnosticFloatingWarn", "DiagnosticFloatingWarn" }, highlights)
  end)

  it("indents a multi-line message and drops its blank lines", function()
    local lines, highlights = hover._format_diagnostics({ diag(0, 0, severity.HINT, "first\n\nsecond") }, icons)
    assert.same({ "H first", "  second" }, lines)
    assert.same({ "DiagnosticFloatingHint", "DiagnosticFloatingHint" }, highlights)
  end)

  it("names the source after the message's first line", function()
    local d = diag(0, 0, severity.ERROR, "first\nsecond")
    d.source = "selene"
    assert.same({ "E first (selene)", "  second" }, (hover._format_diagnostics({ d }, icons)))
  end)
end)

describe("hover.hover", function()
  local buf

  before_each(function()
    buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "one", "two", "three" })
  end)

  after_each(function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("shows the cursor line's diagnostics in a popup when no LSP client is attached", function()
    local ns = vim.api.nvim_create_namespace("hover_spec")
    vim.diagnostic.set(ns, buf, {
      diag(1, 2, severity.WARN, "on the line"),
      diag(1, 0, severity.ERROR, "also on the line"),
      diag(2, 0, severity.ERROR, "next line"),
    })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    hover.hover({})

    local win = vim.b[buf].lsp_floating_preview
    assert.truthy(win and vim.api.nvim_win_is_valid(win))
    local text = table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false), "\n")
    assert.matches("also on the line.*on the line", text)
    assert.falsy(text:find("next line", 1, true))
  end)
end)
