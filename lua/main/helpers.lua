local M = {}

--[[ MAPPING HELPERS ]]

---@alias mode string|table The mode to map.
---| '""' # Regular noremap (all modes)
---| '"n"' # Normal mode
---| '"i"' # Insert mode
---| '"x"' # Visual (alone) mode
---| '"s"' # Select (alone) mode
---| '"v"' # Visual _and_ Select modes
---| '"c"' # Command-line mode
---| '"o"' # Operator-pending mode

---Convenience function that binds a mode to a `vim.keymap.set`.
---@param op mode
---@param outer_opts table? Optional take of options to pass when binding.
local function bind(op, outer_opts)
    -- Defaults
    outer_opts = outer_opts or { noremap = true, silent = true }

    ---Convenience function to create a keymap for mode that has been bound: "{mode}"
    ---     FYI: DO NOT CHANGE THE FUNCTION SIGNATURE OF THIS! It will break in weird ways, since
    ---     it expects things to be named "op"/"lhs"/"rhs"/"opts". Fun!
    ---@param lhs string The mapping to set.
    ---@param rhs string|function The command to execute when the mapping is used.
    ---@param opts? table Options to pass. These are the same options as for `vim.api.nvim_set_keymap`.
    return function(lhs, rhs, opts)
        -- Defaults
        opts = vim.tbl_extend("force",
            outer_opts,
            opts or {}
        )

        vim.keymap.set(op, lhs, rhs, opts)
    end
end

M.nmap = bind("n", { noremap = false, silent = true })
M.vmap = bind("v", { noremap = false, silent = true })
M.noremap = bind("")
M.nnoremap = bind("n")
M.inoremap = bind("i")
M.xnoremap = bind("x")
M.vnoremap = bind("v")
M.cnoremap = bind("c")
M.onoremap = bind("o")

---Convenience function that wraps the given string with `<Cmd>` and `<CR>`
---@param command string The command to wrap.
M.cmd = function (command)
    return "<Cmd>" .. command .. "<CR>"
end

return M

