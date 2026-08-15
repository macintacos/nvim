---Document-symbol picker rendered as the file's outline.
---
---`MiniExtra.pickers.lsp` can't back this one: it routes through
---`vim.lsp.util.symbols_to_items`, which recurses into `children` and appends
---them to one flat list, so the nesting is gone before the picker sees it.
---This asks the server directly and keeps the tree.

local kinds = require("plugins.mini-pickers.kinds")
local render = require("plugins.mini-pickers.render")
local symbols = require("plugins.mini-pickers.symbols")

local M = {}

---`source.show` for the outline.
---
---Idle, rows sit in document order and carry tree connectors. A query reorders
---them by fuzzy score, which would make those connectors describe a tree that
---is no longer on screen — so they give way to a breadcrumb trail printed above
---each hit. The trail is a *virtual* line: mini.pick maps one item to one
---buffer line by position (`H.picker_set_lines`), so a real line would break
---selection, and virtual ones also get the full window width to spend.
---@param buf_id integer
---@param items MiniPickers.Symbol[]
---@param query string[]
local function show(buf_id, items, query)
  local icons, hls, display = {}, {}, {}
  for i, item in ipairs(items) do
    local ok, icon, hl = pcall(MiniIcons.get, "lsp", item.kind)
    icons[i], hls[i] = ok and icon or " ", ok and hl or "Normal"
    display[i] = vim.tbl_extend("force", item, { text = icons[i] .. " " .. item.name })
  end

  MiniPick.default_show(buf_id, display, query)

  local state = MiniPick.get_picker_state()
  local width = state and vim.api.nvim_win_get_width(state.windows.main) or 80
  local searching = #query > 0

  vim.api.nvim_buf_clear_namespace(buf_id, render.ns, 0, -1)
  local prev_crumb, first_has_trail = nil, false
  for i, item in ipairs(items) do
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
      end_col = #icons[i],
      hl_group = hls[i],
      priority = 199,
    })
    vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
      virt_text = { { item.kind, render.kind_hl(item.kind, hls[i]) } },
      virt_text_pos = "right_align",
      priority = 199,
    })

    if not searching then
      if item.guides ~= "" then
        vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
          virt_text = { { item.guides, "Comment" } },
          virt_text_pos = "inline",
          priority = 199,
        })
      end
    elseif item.crumb ~= "" then
      -- One trail per run of hits sharing it. Score order usually scatters
      -- siblings, but when it doesn't, repeating the same trail is pure noise.
      if item.crumb ~= prev_crumb then
        vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
          virt_lines = { { { symbols.fit(item.crumb, width), render.crumb_hl() } } },
          virt_lines_above = true,
          priority = 199,
        })
        first_has_trail = first_has_trail or i == 1
      end
      -- Indent the hits so the trail's first glyph sits left of what it covers.
      vim.api.nvim_buf_set_extmark(buf_id, render.ns, i - 1, 0, {
        virt_text = { { "  " } },
        virt_text_pos = "inline",
        priority = 199,
      })
    end
    prev_crumb = item.crumb
  end

  if state then
    render.reserve_trail_row(state.windows.main, first_has_trail)
  end
end

-- Exposed for tests: driving the renderer directly avoids needing a live LSP.
M._show = show

---Open the outline for the current buffer.
---
---Items are matched on their `text` (the bare name), which is what makes the
---default fuzzy match honest here without a `source.match` override.
function M.pick()
  local buf = vim.api.nvim_get_current_buf()
  if #vim.lsp.get_clients({ bufnr = buf, method = "textDocument/documentSymbol" }) == 0 then
    return vim.notify("No LSP client provides document symbols", vim.log.levels.WARN)
  end

  local keep = kinds.for_filetype(vim.bo[buf].filetype)
  local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
  vim.lsp.buf_request_all(buf, "textDocument/documentSymbol", params, function(results)
    local items = {}
    for id, res in pairs(results) do
      local client = vim.lsp.get_client_by_id(id)
      local opts = { bufnr = buf, kinds = keep, encoding = client and client.offset_encoding }
      vim.list_extend(items, symbols.flatten(res.result or {}, opts))
    end
    MiniPick.start({
      source = { items = items, name = "LSP (document_symbol)", show = show },
    })
  end)
end

return M
