--Default Settings

--[[

Default mappings:

    Remaps normal mode macro record q to Q
    nnoremap Q q
    nmap q        <Plug>(smartq_this)
    nmap <C-q>    <Plug>(smartq_this_force)

--]]
vim.g.smartq_default_mappings = 1

-- Excluded buffers to disable SmartQ and to preserve windows when closing splits
-- on excluded buffers. Non-modifiable buffers are preserved by default.
vim.g.smartq_exclude_filetypes = { "fugitive" }
vim.g.smartq_exclude_buftypes = { "" }

-- Quit buffers using :q command. Non-modifiable and readonly file uses :q
vim.g.smartq_q_filetypes = {
    "diff",
    "git",
    "gina-status",
    "gina-commit",
    "snippets",
    "floaterm",
}
vim.g.smartq_q_buftypes = { "quickfix", "nofile" }
--
-- Wipe buffers using :bw command. Wiped buffers are removed from jumplist
-- Default :bd
vim.g.smartq_bw_filetypes = { "" }
vim.g.smartq_bw_buftypes = { "" }

-- Automatically wipe empty (with no changes) buffer(s)
vim.g.smartq_auto_wipe_emtpy = 1

-- Best attempt to prevent exiting editor when left with an empty modifiable buffer
vim.g.smartq_no_exit = 0

-- Automatically close splits when left with 1 modifiable buffer
vim.g.smartq_auto_close_splits = 0

--[[ PLUGIN INTEGRATIONS ]]
-- When a plugin is disabled, use built-in fallbacks

-- Enable Goyo
vim.g.smartq_goyo_integration = 1

-- Enable Zen-mode
vim.g.smartq_zenmode_integration = 1
