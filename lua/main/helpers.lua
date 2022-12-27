local M = {}

--[[ MAPPING HELPERS ]]

---Convenience function that binds a mode to a `vim.keymap.set`.
---@param mode string|table The mode to map.
---| '""' # Regular noremap (all modes)
---| '"n"' # Normal mode
---| '"i"' # Insert mode
---| '"x"' # Visual (alone) mode
---| '"s"' # Select (alone) mode
---| '"v"' # Visual _and_ Select modes
---| '"c"' # Command-line mode
---| '"o"' # Operator-pending mode
---@param outer_opts table? Optional take of options to pass when binding.
local function bind(mode, outer_opts)
    -- Defaults
    outer_opts = outer_opts or { noremap = true, silent = true }

    ---Convenience function to create a keymap for mode that has been bound: "{mode}"
    ---@param lhs string The mapping to set.
    ---@param rhs string|function The command to execute when the mapping is used.
    ---@param mode_override? string|table The mode to override, if necessary.
    ---@param opts? table Options to pass. These are the same options as for `vim.api.nvim_set_keymap`.
    return function(lhs, rhs, mode_override, opts)
        -- Defaults
        opts = vim.tbl_extend("force",
            outer_opts,
            opts or {}
        )
        mode = mode_override or mode

        vim.keymap.set(mode, lhs, rhs, opts)
    end
end

M.nmap = bind("n", { noremap = false })
M.noremap = bind("")
M.nnoremap = bind("n")
M.inoremap = bind("i")
M.xnoremap = bind("x")
M.vnoremap = bind("v")
M.cnoremap = bind("c")
M.onoremap = bind("o")
M.flexnoremap = bind({}) -- use this when you want to specify a table of modes manually

return M
