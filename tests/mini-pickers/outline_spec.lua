local outline = require("plugins.mini-pickers.outline")

local KIND = vim.lsp.protocol.SymbolKind

---A `DocumentSymbol` named `name` declared on (0-based) `line`.
---@param name string
---@param kind integer
---@param line integer
---@return table
local function sym(name, kind, line)
  local start = { line = line, character = 0 }
  return {
    name = name,
    kind = kind,
    range = { start = start, ["end"] = { line = line, character = 80 } },
    selectionRange = { start = start, ["end"] = { line = line, character = #name } },
  }
end

---Collect one field across a list of items.
---@param items table[]
---@return string[]
local function names(items)
  local out = {}
  for i, item in ipairs(items) do
    out[i] = item.name
  end
  return out
end

describe("mini-pickers.outline", function()
  describe("_collect", function()
    local buf

    before_each(function()
      buf = vim.api.nvim_create_buf(false, true)
    end)

    after_each(function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it("returns the response filtered to the requested kinds", function()
      local response = {
        [1] = { result = { sym("handler", KIND.Function, 0), sym("limit", KIND.Variable, 3) } },
      }
      local items, fell_back = outline._collect(response, buf, { Variable = true })

      assert.same({ "limit" }, names(items))
      assert.is_false(fell_back)
    end)

    it("falls back to every kind when the filter matches nothing", function()
      local response = { [1] = { result = { sym("handler", KIND.Function, 0) } } }
      local items, fell_back = outline._collect(response, buf, { Variable = true })

      assert.same({ "handler" }, names(items))
      assert.is_true(fell_back)
    end)

    it("does not report a fallback when the file has no symbols at all", function()
      local response = { [1] = { result = {} } }
      local items, fell_back = outline._collect(response, buf, { Variable = true })

      assert.same({}, items)
      assert.is_false(fell_back)
    end)
  end)
end)
