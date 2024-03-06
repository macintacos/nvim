local M = {}

--[[ MAPPING HELPERS ]]

---@alias mode string The mode to map.
---| '""' # Regular noremap (all modes)
---| '"n"' # Normal mode
---| '"i"' # Insert mode
---| '"x"' # Visual (alone) mode
---| '"s"' # Select (alone) mode
---| '"v"' # Visual _and_ Select modes
---| '"c"' # Command-line mode
---| '"o"' # Operator-pending mode

---Convenience function that binds a mode to a `vim.keymap.set`.
---@param mode mode
---@param lhs string The mapping to set.
---@param rhs string The command to execute when the mapping is used.
---@param opts table? Optional take of options to pass when binding.
local function map(mode, lhs, rhs, opts)
    -- Defaults
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend("force", options, opts)
    end

    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

function M.nmap(lhs, rhs, opts)
    map("n", lhs, rhs, { noremap = false, silent = true })
end
function M.vmap(lhs, rhs, opts)
    map("v", lhs, rhs, { noremap = false, silent = true })
end
function M.noremap(lhs, rhs, opts)
    map("", lhs, rhs, opts)
end
function M.nnoremap(lhs, rhs, opts)
    map("n", lhs, rhs, opts)
end
function M.inoremap(lhs, rhs, opts)
    map("i", lhs, rhs, opts)
end
function M.xnoremap(lhs, rhs, opts)
    map("x", lhs, rhs, opts)
end
function M.vnoremap(lhs, rhs, opts)
    map("v", lhs, rhs, opts)
end
function M.cnoremap(lhs, rhs, opts)
    map("c", lhs, rhs, opts)
end
function M.onoremap(lhs, rhs, opts)
    map("o", lhs, rhs, opts)
end

---Convenience function that wraps the given string with `<Cmd>` and `<CR>`
---@param command string The command to wrap.
M.cmd = function(command)
    return "<Cmd>" .. command .. "<CR>"
end

return M
