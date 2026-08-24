-- github.com/jakewvincent/mkdnflow.nvim
-- Fluent navigation and management of markdown
vim.pack.add({ "https://github.com/jakewvincent/mkdnflow.nvim" })

-- Reroute mkdnflow's default <leader>-prefixed mappings to <localleader>
-- so they live behind a markdown-flavored prefix instead of crowding the
-- <Space> leader namespace. With g:maplocalleader = "," these resolve to
-- ",X" buffer-local mappings on each FileType=markdown event.
require("mkdnflow").setup({
  mappings = {
    -- Insert-mode <Tab>/<S-Tab> default to MkdnTableNextCell/MkdnTablePrevCell,
    -- which no-op outside a table, so the keys do nothing in a list. MkdnTab and
    -- MkdnSTab keep the cell jump and add indent/dedent of the list item under
    -- the cursor, falling through to a literal <Tab> anywhere else.
    MkdnTab = { "i", "<Tab>" },
    MkdnSTab = { "i", "<S-Tab>" },
    MkdnTableNextCell = false,
    MkdnTablePrevCell = false,
    MkdnUpdateNumbering = { "n", "<localleader>nn" },
    MkdnTableNewRowBelow = { "n", "<localleader>ir" },
    MkdnTableNewRowAbove = { "n", "<localleader>iR" },
    MkdnTableNewColAfter = { "n", "<localleader>ic" },
    MkdnTableNewColBefore = { "n", "<localleader>iC" },
    MkdnTableDeleteRow = { "n", "<localleader>dr" },
    MkdnTableDeleteCol = { "n", "<localleader>dc" },
    MkdnTableAlignLeft = { "n", "<localleader>al" },
    MkdnTableAlignRight = { "n", "<localleader>ar" },
    MkdnTableAlignCenter = { "n", "<localleader>ac" },
    MkdnTableAlignDefault = { "n", "<localleader>ax" },
    MkdnCreateLinkFromClipboard = { { "n", "v" }, "<localleader>p" },
  },
})
