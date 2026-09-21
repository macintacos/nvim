local data = vim.fn.stdpath("data") .. "/site/pack/"
vim.opt.rtp:prepend(vim.fn.glob(data .. "*/opt/mini.pick", false, true)[1])
require("mini.pick").setup()

local registry = require("plugins.mini-pickers.init")

describe("mini-pickers registry", function()
  local captured, buf

  before_each(function()
    -- mini.extra's lsp picker is the boundary the registry hands its opts to;
    -- standing in for it keeps the LSP roundtrip out while the contract —
    -- what the registry asks for — stays under test.
    captured = nil
    MiniExtra = {
      pickers = {
        lsp = function(local_opts, opts)
          captured = { local_opts = local_opts, opts = opts }
        end,
      },
    }
    registry.setup()

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local needle = 1" })
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_win_set_cursor(0, { 1, 6 })
  end)

  after_each(function()
    MiniExtra = nil
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("seeds a workspace_symbol query with the word under the cursor", function()
    MiniPick.registry.lsp({ scope = "workspace_symbol" })

    assert.equal("needle", captured.local_opts.symbol_query)
  end)

  it("keeps a symbol_query the caller already set", function()
    MiniPick.registry.lsp({ scope = "workspace_symbol", symbol_query = "explicit" })

    assert.equal("explicit", captured.local_opts.symbol_query)
  end)

  it("leaves workspace_symbol_live unseeded; its query is typed in the picker", function()
    MiniPick.registry.lsp({ scope = "workspace_symbol_live" })

    assert.is_nil(captured.local_opts.symbol_query)
  end)
end)
