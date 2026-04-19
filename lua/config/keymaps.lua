local map = vim.keymap.set
local helpers = require("config.helpers")
local Cmd = helpers.Cmd

-- Unmap 'q'
map("n", "q", "<nop>", { remap = false })

-- Don't copy things you've pasted over
map("v", "p", '"_dP')

-- make 'Y' yank from current character to end of line
map("n", "Y", "y$", { desc = "Yank to Line End" })
map("v", "y", "ygv<ESC>")

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Resize windows using Alt+WASD
map("n", "<A-w>", Cmd("resize +2"), { desc = "Increase Window Height" })
map("n", "<A-s>", Cmd("resize -2"), { desc = "Decrease Window Height" })
map("n", "<A-a>", Cmd("vertical resize -2"), { desc = "Decrease Window Width" })
map("n", "<A-d>", Cmd("vertical resize +2"), { desc = "Increase Window Width" })

-- Move Lines (scrolls LSP hover popup first, if one is open)
map("n", "J", function()
  if helpers.scroll_hover("down") then
    return
  end
  vim.cmd("execute 'move .+' . v:count1")
  vim.cmd("normal! ==")
end, { desc = "Scroll Hover / Move Down" })
map("n", "K", function()
  if helpers.scroll_hover("up") then
    return
  end
  vim.cmd("execute 'move .-' . (v:count1 + 1)")
  vim.cmd("normal! ==")
end, { desc = "Scroll Hover / Move Up" })
map("v", "J", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "K", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Better indentation
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Save, no matter what
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- Dupe lines up/down
map("n", "<A-j>", Cmd("t."), { desc = "Copy line down" })
map("n", "<A-k>", Cmd("t-1"), { desc = "Copy line up" })
map("v", "<A-j>", "y`>pgv", { desc = "Copy lines down" })
map("v", "<A-k>", "y`<Pgv", { desc = "Copy line up" })

-- Terminal
map("n", "<C-'>", function()
  Snacks.terminal()
end, { desc = "Terminal" })
map("t", "<C-'>", function()
  Snacks.terminal()
end, { desc = "Terminal" })

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

vim.keymap.set("n", "<C-\\>", neo_tree_focus_toggle, { noremap = true, silent = true })

-- Join the next/prev line with the current
map("n", "<A-J>", Cmd("norm! J"), { desc = "Join Current Line w/ Next" })
map("n", "<A-K>", Cmd(".-1,.join"), { desc = "Join Current Line w/ Prev" })

-- Select parent/child treesitter node (falls back to LSP selection range)
map({ "n", "x", "o" }, "<A-o>", function()
  if vim.treesitter.get_parser(nil, nil, { error = false }) then
    require("vim.treesitter._select").select_parent(vim.v.count1)
  else
    vim.lsp.buf.selection_range(vim.v.count1)
  end
end, { desc = "Select Parent Node" })

map({ "n", "x", "o" }, "<A-i>", function()
  if vim.treesitter.get_parser(nil, nil, { error = false }) then
    require("vim.treesitter._select").select_child(vim.v.count1)
  else
    vim.lsp.buf.selection_range(-vim.v.count1)
  end
end, { desc = "Select Child Node" })
