local go_folds = require("plugins.go-folds")
local start_server = require("support.lsp").start_server

vim.opt.rtp:prepend(require("support.deps").path("nvim-treesitter") .. "/runtime")

local LINES = {
  "package p",
  "func f(err error) int {",
  "\tif err != nil {",
  "\t\treturn 1",
  "\t}",
  "\treturn 0",
  "}",
}

describe("go-folds", function()
  ---@type integer
  local buf

  before_each(function()
    vim.cmd("enew!")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".go")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, LINES)
    vim.bo[buf].filetype = "go"
    vim.bo[buf].tabstop = 4
    vim.o.columns = 120
    vim.opt.fillchars = { foldclose = "+" }
    vim.wo.foldlevel = 99
    vim.wo.foldtext = "v:lua.require'plugins.go-folds'.foldtext()"
  end)

  after_each(function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop(true)
    end
    vim.diagnostic.reset()
    vim.cmd("bwipeout!")
  end)

  describe("foldtext", function()
    ---Text of the closed fold over `first` to `last`, 1-indexed.
    ---@param first integer
    ---@param last integer
    ---@return string
    local function folded(first, last)
      vim.wo.foldmethod = "manual"
      vim.cmd(("%d,%dfold"):format(first, last))
      return (vim.fn.foldtextresult(first):gsub("%s+$", ""))
    end

    it("draws a closed construct as one line of Go, marked with the gutter's chevron", function()
      assert.equal("    if err != nil { return 1 } +", folded(3, 5))
    end)

    it("keeps the code's syntax colors", function()
      local construct = assert(go_folds._construct(buf, 2))
      local groups = {}
      for _, chunk in ipairs(go_folds._chunks(buf, construct)) do
        groups[vim.trim(chunk[1])] = chunk[2][#chunk[2]]
      end
      assert.equal("@keyword.conditional.go", groups["if"])
      assert.equal("@keyword.return.go", groups["return"])
      assert.equal("@number.go", groups["1"])
    end)

    it("counts the diagnostics the hidden lines carry", function()
      vim.diagnostic.set(vim.api.nvim_create_namespace("go-folds-spec"), buf, {
        { lnum = 3, col = 2, message = "boom", severity = vim.diagnostic.severity.ERROR },
      })
      assert.equal("    if err != nil { return 1 } + E 1", folded(3, 5))
    end)

    it("draws the bar for a fold that is no construct", function()
      assert.is_truthy(folded(2, 7):find("⣿", 1, true))
    end)

    it("draws the bar for a fold that stops short of a construct's closing brace", function()
      assert.is_truthy(folded(3, 4):find("⣿", 1, true))
    end)

    it("draws the bar for a construct whose one line overruns the window", function()
      vim.o.columns = 30
      assert.is_truthy(folded(3, 5):find("⣿", 1, true))
    end)
  end)

  describe("attach", function()
    ---Fold the window by a server that reports `ranges`, the way gopls attaching does.
    ---@param ranges lsp.FoldingRange[]
    local function attach(ranges)
      local client = start_server(buf, { foldingRangeProvider = true, textDocumentSync = 1 }, ranges)
      go_folds.attach(client, buf)
      require("config.folds").fold_imports(client, buf)
    end

    ---Wait for the fold at 1-indexed `lnum` to close, and return its extent.
    ---@param lnum integer
    ---@return integer[]
    local function closed(lnum)
      vim.wait(1000, function()
        return vim.fn.foldclosed(lnum) ~= -1
      end)
      return { vim.fn.foldclosed(lnum), vim.fn.foldclosedend(lnum) }
    end

    -- gopls ends a block's range on the line before its closing brace.
    local RANGES = { { startLine = 1, endLine = 5 }, { startLine = 2, endLine = 3 } }

    it("closes each construct over its closing brace, and nothing else", function()
      attach(RANGES)
      assert.same({ 3, 5 }, closed(3))
      assert.equal(-1, vim.fn.foldclosed(2))
    end)

    it("reopens and recloses a construct with the fold keys", function()
      attach(RANGES)
      closed(3)
      vim.cmd("normal! 3Gzo")
      assert.equal(-1, vim.fn.foldclosed(3))
      vim.cmd("normal! zc")
      assert.same({ 3, 5 }, closed(3))
    end)

    it("leaves a construct the user opened open when the ranges refresh", function()
      attach(RANGES)
      closed(3)
      vim.cmd("3foldopen")
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "" })
      vim.wait(200)
      assert.equal(-1, vim.fn.foldclosed(3))
    end)

    it("still closes the import block", function()
      vim.api.nvim_buf_set_lines(buf, 1, 1, false, { "import (", '\t"os"', ")" })
      attach({
        { startLine = 1, endLine = 2, kind = "imports" },
        { startLine = 4, endLine = 8 },
        { startLine = 5, endLine = 6 },
      })
      assert.same({ 2, 4 }, closed(2))
      assert.same({ 6, 8 }, closed(6))
    end)
  end)
end)
