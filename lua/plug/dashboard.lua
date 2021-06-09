local gvar = vim.api.nvim_set_var

gvar("dashboard_default_executive", "telescope")

-- TODO: Make these actually correspond to the correct keybindings
gvar("dashboard_custom_shortcut", {
    last_session = 'SPC s l',
    find_history = 'SPC f h',
    find_file = 'SPC f f',
    new_file = 'SPC c n',
    change_colorscheme = 'SPC t c',
    find_word = 'SPC f a',
    book_marks = 'SPC f b',
})

gvar("dashboard_custom_header", {
    ' ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗',
    ' ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║',
    ' ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║',
    ' ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║',
    ' ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║',
    ' ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝',
})

-- TODO: Look into 'dashboard_custom_section' in the documentation - maybe some other things to add in the future that'd be nice to have?