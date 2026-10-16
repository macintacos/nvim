local folds = require("config.folds")

describe("bar", function()
  it("fills the width exactly", function()
    local line = folds._bar("fn foo()", "3 lines · 10.0%", 80)
    assert.equal(80, vim.api.nvim_strwidth(line))
  end)

  it("truncates the title rather than pushing the summary off the edge", function()
    local line = folds._bar("local function a_very_long_name(alpha, beta)", "3 lines · 10.0%", 40)
    assert.equal(40, vim.api.nvim_strwidth(line))
    assert.is_true(line:find("3 lines · 10.0%", 1, true) ~= nil)
    assert.is_true(line:find("…", 1, true) ~= nil)
  end)

  it("drops the title entirely when even the summary barely fits", function()
    local line = folds._bar("local function foo()", "3 lines · 10.0%", 25)
    assert.is_true(line:find("3 lines · 10.0%", 1, true) ~= nil)
    assert.is_nil(line:find("foo", 1, true))
  end)
end)

describe("foldtext", function()
  it("stops at column 100 in a wider window", function()
    vim.o.columns = 200
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "function foo()", "  return 1", "  -- two", "end" })
    vim.bo.shiftwidth = 2
    vim.wo.foldmethod = "indent"
    vim.wo.foldtext = "v:lua.require'config.folds'.foldtext()"
    vim.cmd("normal! zM")
    assert.equal(100, vim.api.nvim_strwidth(vim.fn.foldtextresult(2)))
  end)

  ---Fold text for lines 1-2 of a parsed buffer holding `lines` as `filetype`.
  ---@param filetype string
  ---@param lines string[]
  ---@return string
  local function folded(filetype, lines)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.filetype = filetype
    assert(vim.treesitter.get_parser(0)):parse()
    vim.wo.foldmethod = "manual"
    vim.wo.foldtext = "v:lua.require'config.folds'.foldtext()"
    vim.cmd("1,2fold")
    return vim.fn.foldtextresult(1)
  end

  for _, case in ipairs({
    { "python", { "import os", "import sys" } },
    { "python", { "from os import path", "from sys import argv" } },
    { "go", { "import (", ")" } },
    { "typescript", { 'import a from "a";', 'import b from "b";' } },
    { "rust", { "use std::fmt;", "use std::io;" } },
  }) do
    local filetype, lines = case[1], case[2]
    it(("titles a %s block opening with `%s` 'imports'"):format(filetype, lines[1]), function()
      local text = folded(filetype, lines)
      assert.is_truthy(text:find("imports", 1, true))
      assert.is_falsy(text:find(lines[1], 1, true))
    end)
  end

  it("titles any other fold with its first line", function()
    local text = folded("python", { "def main():", "    return 1" })
    assert.is_truthy(text:find("def main():", 1, true))
  end)
end)

describe("fold_imports", function()
  ---Start a client on `buf` against an in-process server that answers
  ---`textDocument/foldingRange` with `ranges`.
  ---@param buf integer
  ---@param capabilities lsp.ServerCapabilities
  ---@param ranges lsp.FoldingRange[]
  ---@return vim.lsp.Client
  local function start_server(buf, capabilities, ranges)
    local id = assert(vim.lsp.start({
      name = "fake",
      cmd = function(dispatchers)
        local closing = false
        local requests = 0
        return {
          request = function(method, _, callback)
            requests = requests + 1
            if method == "initialize" then
              callback(nil, { capabilities = capabilities })
            elseif method == "textDocument/foldingRange" then
              callback(nil, ranges)
            elseif method == "shutdown" then
              callback(nil, nil)
            end
            return true, requests
          end,
          notify = function(method)
            if method == "exit" then
              dispatchers.on_exit(0, 15)
            end
            return true
          end,
          is_closing = function()
            return closing
          end,
          terminate = function()
            closing = true
          end,
        }
      end,
    }, { bufnr = buf }))
    assert.is_true(vim.wait(1000, function()
      return vim.lsp.buf_is_attached(buf, id)
    end))
    return assert(vim.lsp.get_client_by_id(id))
  end

  ---@type integer
  local buf

  before_each(function()
    vim.cmd("enew!")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(buf, vim.fn.tempname() .. ".py")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "import os",
      "import sys",
      "",
      "def main():",
      "    return os, sys",
    })
    vim.bo[buf].filetype = "python"
    vim.wo.foldlevel = 99
    vim.wo.foldmethod = "indent"
  end)

  after_each(function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      client:stop(true)
    end
    vim.cmd("bwipeout!")
  end)

  it("closes the import block the server reports, and only that", function()
    local client = start_server(buf, { foldingRangeProvider = true }, {
      { startLine = 0, endLine = 1, kind = "imports" },
      { startLine = 3, endLine = 4 },
    })
    require("config.folds").fold_imports(client, buf)
    vim.wait(1000, function()
      return vim.fn.foldclosed(1) ~= -1
    end)
    assert.same({ 1, 2 }, { vim.fn.foldclosed(1), vim.fn.foldclosedend(1) })
    assert.equal(-1, vim.fn.foldclosed(4))
  end)

  it("folds away the `)` closing an import block whose range stops short of it", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "package main",
      "",
      "import (",
      '\t"fmt"',
      '\t"os"',
      ")",
    })
    vim.bo[buf].filetype = "go"
    local client = start_server(buf, { foldingRangeProvider = true }, {
      { startLine = 2, endLine = 4, kind = "imports" },
    })
    require("config.folds").fold_imports(client, buf)
    vim.wait(1000, function()
      return vim.fn.foldclosed(3) ~= -1
    end)
    assert.same({ 3, 6 }, { vim.fn.foldclosed(3), vim.fn.foldclosedend(3) })
  end)

  it("closes import blocks that only blank lines part as one fold", function()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "import os",
      "import sys",
      "",
      "from a import (",
      "    b,",
      ")",
      "",
      "def main():",
      "    return os, sys, b",
    })
    local client = start_server(buf, { foldingRangeProvider = true }, {
      { startLine = 0, endLine = 1, kind = "imports" },
      { startLine = 3, endLine = 5, kind = "imports" },
      { startLine = 7, endLine = 8 },
    })
    require("config.folds").fold_imports(client, buf)
    vim.wait(1000, function()
      return vim.fn.foldclosed(1) ~= -1
    end)
    assert.same({ 1, 6 }, { vim.fn.foldclosed(1), vim.fn.foldclosedend(1) })
    assert.equal(-1, vim.fn.foldclosed(8))
  end)

  it("keeps the window's folds when the server serves no folding ranges", function()
    local client = start_server(buf, {}, {})
    require("config.folds").fold_imports(client, buf)
    vim.wait(100)
    assert.equal(1, vim.fn.foldlevel(5))
  end)
end)

describe("summary", function()
  it("says line, not lines, for a single hidden line", function()
    assert.equal("1 line · 12.5%", folds._summary(1, {}, 8))
  end)

  it("puts diagnostic counts ahead of the size", function()
    assert.equal(" 2 ⣹⣿⣏ 4 lines · 50.0%", folds._summary(4, { " 2" }, 8))
  end)
end)
