local map = require("helpers.mappings").map
local Cmd = require("helpers.mappings").Cmd
local windows = require("helpers.windows")

-- Unmap 'q'
map("Unmap q", "n", "q", "<nop>")

-- Don't copy things you've pasted over
map("No-yank paste", "v", "p", '"_dP')

-- make 'Y' yank from current character to end of line
map("Yank to Line End", "n", "Y", "y$")
map("Yank and reselect", "v", "y", "ygv<ESC>")

-- better up/down
map("Down", { "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("Down", { "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("Down", { "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("Down", { "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("Up", { "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("Up", { "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("Up", { "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("Up", { "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Jump to end of line (replaces the default "lowest line in window")
map("End of Line", { "n", "x" }, "L", "$")

-- Resize windows using Alt+WASD
map("Increase Window Height", "n", "<A-w>", Cmd("resize +2"))
map("Decrease Window Height", "n", "<A-s>", Cmd("resize -2"))
map("Decrease Window Width", "n", "<A-a>", Cmd("vertical resize -2"))
map("Increase Window Width", "n", "<A-d>", Cmd("vertical resize +2"))

-- Move Lines (scrolls LSP hover popup first, if one is open)
map("Scroll Hover / Move Down", "n", "J", function()
  if windows.scroll_hover("down") then
    return
  end
  vim.cmd("execute 'move .+' . v:count1")
  vim.cmd("normal! ==")
end)
map("Scroll Hover / Move Up", "n", "K", function()
  if windows.scroll_hover("up") then
    return
  end
  vim.cmd("execute 'move .-' . (v:count1 + 1)")
  vim.cmd("normal! ==")
end)
map("Move Down", "v", "J", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv")
map("Move Up", "v", "K", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv")

-- Better indentation
map("Indent left and reselect", "v", "<", "<gv")
map("Indent right and reselect", "v", ">", ">gv")

-- Clear search and stop snippet on escape
map("Escape and Clear hlsearch", { "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true })

-- Add undo break-points
map("Undo break-point at ,", "i", ",", ",<c-g>u")
map("Undo break-point at .", "i", ".", ".<c-g>u")
map("Undo break-point at ;", "i", ";", ";<c-g>u")

-- Save, no matter what
map("Save File", { "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>")

-- Dupe lines up/down
map("Copy line down", "n", "<A-j>", Cmd("t."))
map("Copy line up", "n", "<A-k>", Cmd("t-1"))
map("Copy lines down", "v", "<A-j>", "y`>pgv")
map("Copy line up", "v", "<A-k>", "y`<Pgv")

-- Terminal
map("Terminal", "n", "<C-'>", function()
  Snacks.terminal()
end)
map("Terminal", "t", "<C-'>", function()
  Snacks.terminal()
end)

-- Focus Neotree using CTRL-\
local function neo_tree_focus_toggle()
  local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
  if ft == "neo-tree" then
    vim.cmd("Neotree close")
    return
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    if bft == "neo-tree" then
      vim.cmd("Neotree focus right")
      return
    end
  end

  vim.cmd("Neotree focus right")
end

map("Toggle neo-tree focus", "n", "<C-\\>", neo_tree_focus_toggle, { silent = true })

-- Join the next/prev line with the current
map("Join Current Line w/ Next", "n", "<A-J>", Cmd("norm! J"))
map("Join Current Line w/ Prev", "n", "<A-K>", Cmd(".-1,.join"))

-- Select parent/child treesitter node (falls back to LSP selection range)
map("Select Parent Node", { "n", "x", "o" }, "<A-o>", function()
  if vim.treesitter.get_parser(nil, nil, { error = false }) then
    require("vim.treesitter._select").select_parent(vim.v.count1)
  else
    vim.lsp.buf.selection_range(vim.v.count1)
  end
end)

map("Select Child Node", { "n", "x", "o" }, "<A-i>", function()
  if vim.treesitter.get_parser(nil, nil, { error = false }) then
    require("vim.treesitter._select").select_child(vim.v.count1)
  else
    vim.lsp.buf.selection_range(-vim.v.count1)
  end
end)

-- Jump and center
map("Jump to Next Empty", "n", "}", "}zz")
map("Jump to Prev Empty", "n", "{", "{zz")
