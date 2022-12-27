vim.g.mapleader = " " -- SPC as leader key

--[[ HELPER FUNCTIONS ]]

---@alias mode
---| '"n"' # Normal mode
---| '"i"' # Insert mode
---| '"x"' # Visual (alone) mode
---| '"s"' # Select (alone) mode
---| '"v"' # Visual _and_ Select modes
---| '"c"' # Command-line mode
---| '"o"' # Operator-pending mode

---@param mode mode|mode[] The mode to map.
---@param map string The mapping to set.
---@param cmd string The command to execute when the mapping is used.
---@param opts? table Options to pass. These are the same options as for `vim.api.nvim_set_keymap`.
local function noremap(mode, map, cmd, opts)
	-- Default values
	mode = mode or "n"
	opts = opts or { noremap = true, silent = true }

	vim.api.nvim_set_keymap(mode, map, cmd, opts)
end

--[[ REMAPS ]]

-- C-s saves in all modes
noremap("n", "<C-s>", "<Cmd>w<CR>")
noremap("i", "<C-s>", "<Cmd>w<CR>")
noremap("v", "<C-s>", "<Cmd>w<CR>")
noremap("x", "<C-s>", "<Cmd>w<CR>")

-- j/k moves visually up and down lines, until you want to jump lines.
-- This is more intuitive than the default behavior.
noremap("", "j", "( v:count? 'j': 'gj')", { expr = true, noremap = true })
noremap("", "k", "( v:count? 'k': 'gk')", { expr = true, noremap = true })

-- make 'Y' yank from current character to end of line
noremap("", "Y", "y$", {})
noremap("v", "y", "ygv<ESC>", {})

-- Horizontal scrolling when wrapped
noremap("n", "<C-l>", "20zl")
noremap("n", "<C-h>", "20zh")

-- 'zz'-based mappings - center after performing an action
noremap("n", "G", "Gzz")
noremap("n", "<C-d>", "<C-d>zz")
noremap("n", "<C-u>", "<C-u>zz")
noremap("n", "n", "nzzzv") 
noremap("n", "N", "Nzzzv")



