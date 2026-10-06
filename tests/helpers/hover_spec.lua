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

  describe("with LSP clients", function()
    local originals = {}
    local clients = { [1] = { id = 1, name = "lua_ls" }, [2] = { id = 2, name = "changeset" } }

    ---@param attached integer[] Ids of the clients attached to the buffer
    ---@param results table<integer, { result: lsp.Hover? }>
    local function fake_lsp(attached, results)
      vim.lsp.get_client_by_id = function(id)
        return clients[id]
      end
      vim.lsp.get_clients = function(filter)
        return vim.tbl_filter(
          function(c)
            return not filter.name or c.name == filter.name
          end,
          vim.tbl_map(function(id)
            return clients[id]
          end, attached)
        )
      end
      vim.lsp.buf_request_all = function(_, _, _, handler)
        handler(results)
      end
    end

    local function popup_lines()
      local win = vim.b[buf].lsp_floating_preview
      assert.truthy(win and vim.api.nvim_win_is_valid(win))
      return vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
    end

    before_each(function()
      originals = {
        get_client_by_id = vim.lsp.get_client_by_id,
        get_clients = vim.lsp.get_clients,
        buf_request_all = vim.lsp.buf_request_all,
      }
    end)

    after_each(function()
      for k, v in pairs(originals) do
        vim.lsp[k] = v
      end
    end)

    it("puts the changeset client's answer above other clients' docs", function()
      fake_lsp({ 1, 2 }, {
        [1] = { result = { contents = "other docs" } },
        [2] = { result = { contents = "review comment" } },
      })

      hover.hover({})

      local text = table.concat(popup_lines(), "\n")
      assert.matches("review comment.*other docs", text)
    end)

    it("orders the changeset answer, then diagnostics, then other docs", function()
      local ns = vim.api.nvim_create_namespace("hover_spec")
      vim.diagnostic.set(ns, buf, { diag(0, 0, severity.ERROR, "broken") })
      fake_lsp({ 1, 2 }, {
        [1] = { result = { contents = "other docs" } },
        [2] = { result = { contents = "review comment" } },
      })

      hover.hover({})

      local lines = popup_lines()
      assert.matches("review comment.*broken.*other docs", table.concat(lines, "\n"))
      local float_buf = vim.api.nvim_win_get_buf(vim.b[buf].lsp_floating_preview)
      local row = vim.fn.index(lines, "E broken")
      local marks = vim.api.nvim_buf_get_extmarks(float_buf, -1, { row, 0 }, { row, -1 }, { details = true })
      assert.equal("DiagnosticFloatingError", marks[1] and marks[1][4].line_hl_group)
    end)

    it("shows diagnostics above other docs when no changeset client is attached", function()
      local ns = vim.api.nvim_create_namespace("hover_spec")
      vim.diagnostic.set(ns, buf, { diag(0, 0, severity.ERROR, "broken") })
      fake_lsp({ 1 }, { [1] = { result = { contents = "other docs" } } })

      hover.hover({})

      local lines = popup_lines()
      assert.equal("E broken", lines[1])
      assert.matches("broken.*other docs", table.concat(lines, "\n"))
    end)
  end)
end)
