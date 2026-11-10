---An in-process language server for specs that fold by LSP ranges.

local M = {}

---Start a client on `buf` against an in-process server that answers
---`textDocument/foldingRange` with `ranges`.
---@param buf integer
---@param capabilities lsp.ServerCapabilities
---@param ranges lsp.FoldingRange[]
---@return vim.lsp.Client
function M.start_server(buf, capabilities, ranges)
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

return M
