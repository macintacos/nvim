-- github.com/nvim-mini/mini.statuscolumn
-- Builds 'statuscolumn' out of the number, sign, and fold columns.
-- Docs: https://github.com/nvim-mini/mini.statuscolumn/blob/main/doc/mini-statuscolumn.txt
-- In beta with no stable tag yet — tracks main.
vim.pack.add({ "https://github.com/nvim-mini/mini.statuscolumn" })

-- Replaces snacks.statuscolumn, which plugin/snacks.lua disables.
local statuscolumn = require("mini.statuscolumn")

local helper = "v:lua.require'helpers.statuscolumn'"
local line_number = "%{" .. helper .. ".line_number(v:lnum, v:relnum)}"
local wrap_mark = "%{" .. helper .. ".wrap_mark(v:lnum, v:virtnum)}"
local fold_slot = "%{%" .. helper .. ".fold(v:lnum, v:virtnum)%}"

-- mini's own default spec, with two changes: the numbers are drawn here rather
-- than by `%l`, and wrapped rows draw a continuous run ending in an elbow
-- instead of repeating `↳` on every row.
--
-- `%l` is dropped for two reasons. It left-aligns the cursor line under
-- 'number' + 'relativenumber' (see |number_relativenumber|), and it emits bare
-- digits, so a row's width tracks its digit count. Either one moves the rest of
-- the column around under `%=`. line_number pads to a fixed width instead, and
-- every row then lands identically — including the run of wrapped rows, which
-- hangs off the number above it.
--
-- The run under the cursor line asks for CursorLineNr rather than its own
-- colour so that modes.nvim reaches it: that plugin recolours per mode by
-- remapping CursorLineNr in window-local 'winhighlight', which rewrites the
-- group wherever it is drawn, statuscolumn included.
statuscolumn.setup({
  content = statuscolumn.gen_content.main({
    -- Fold markers sit ahead of the `%=`, pinning them to the left edge rather
    -- than letting the padding of a short row push them around. The space ahead
    -- of the signs keeps diagnostic icons off the digits.
    { format = "f=ls", fold = fold_slot, sign = " %s", sep = "▏" },
    { ltype = "virt", lnum = "•" },
    { ltype = "text", lnum = line_number },
    -- `%C` is evaluated per row, so a fold marker otherwise repeats down every
    -- wrapped row of a folded line.
    { ltype = "wrap", fold = " ", lnum = "%#StatuscolumnWrap#" .. wrap_mark .. "%*" },
    { pos = "cursor", ltype = "wrap", lnum = "%#CursorLineNr#" .. wrap_mark .. "%*" },
    { win = "inactive", sep = " " },
    -- mini draws the cursor line's separator in CursorLineNr, which modes.nvim
    -- gives the cursorline background, so a stack of virtual lines under it (a
    -- changeset comment window's room) grows a bar down its left. A group named
    -- in the separator wins over mini's, so these draw it plain.
    { pos = "cursor", ltype = "virt", sep = "%#MiniStatuscolumnSep#▏" },
    { win = "inactive", pos = "cursor", ltype = "virt", sep = "%#MiniStatuscolumnSep# " },
  }),
})

-- Keeps 'numberwidth' at what the column's number field needs, so Neovim's
-- measure of the column is its real width (see helpers.statuscolumn.numberwidth).
-- Fires on a buffer entering a window, which takes that buffer's width, and on
-- text changes, which only ever widen it: gitsigns' unified view widens it for
-- the line numbers of the base it compares against, and narrowing it again would
-- have the two take turns on every edit.
vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged", "TextChangedI" }, {
  callback = function(args)
    local width = require("helpers.statuscolumn").numberwidth(vim.api.nvim_buf_line_count(args.buf))
    local entered = args.event == "BufWinEnter"
    for _, win in ipairs(entered and { vim.api.nvim_get_current_win() } or vim.fn.win_findbuf(args.buf)) do
      local current = vim.wo[win].numberwidth
      if vim.api.nvim_win_get_buf(win) == args.buf and (width > current or (entered and width < current)) then
        vim.wo[win].numberwidth = width
      end
    end
  end,
})

local function set_statuscolumn_hl()
  -- dim_inactive rewrites CursorLineNr to MiniStatuscolumnDimCursor in every
  -- unfocused window, and that group defaults to the flat MiniStatuscolumnDim, so
  -- an unfocused window's cursor line loses its number highlight. Point it back at
  -- CursorLineNr: the other lines stay dimmed, the cursor line stays readable.
  vim.api.nvim_set_hl(0, "MiniStatuscolumnDimCursor", { link = "CursorLineNr" })

  -- mini gives MiniStatuscolumnDim Normal's background, which in an unfocused
  -- window covers a row's number highlight in the fold and separator cells, so
  -- changeset's diff tint stops short of the edge in a preview.
  local dim = vim.api.nvim_get_hl(0, { name = "MiniStatuscolumnDim", link = false }) --[[@as vim.api.keyset.highlight]]
  dim.bg, dim.default = nil, nil
  vim.api.nvim_set_hl(0, "MiniStatuscolumnDim", dim)

  -- CursorLineFold ships without a background, so the cursor line's highlight
  -- stops short of the fold column. modes.nvim gives CursorLineNr and
  -- CursorLineSign the cursorline background but leaves this one out, which is
  -- why only the modes it recolours look right.
  local fold = vim.api.nvim_get_hl(0, { name = "CursorLineFold", link = false }) --[[@as vim.api.keyset.highlight]]
  fold.bg = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false }).bg
  vim.api.nvim_set_hl(0, "CursorLineFold", fold)

  -- Quieter than LineNr's fg3, so the run down a wrapped line reads below the
  -- numbers it hangs off.
  local p = require("helpers.palette").active()
  if p then
    vim.api.nvim_set_hl(0, "StatuscolumnWrap", { fg = p.bg4 })
  end
end

-- Re-apply on ColorScheme because setting a colorscheme clears custom groups and
-- mini.statuscolumn's own ColorScheme handler then restores its default link.
-- Registered after setup() so it runs after that handler.
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statuscolumn_hl })
