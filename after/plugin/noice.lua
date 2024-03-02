require("noice").setup({
    routes = {
        {
            -- Use this route if you want to disable the search matches
            filter = { event = "msg_show", kind = "search_count" },
            opts = { skip = true },
        },
    },

    views = {
        mini = {
            align = "message-left", -- FIXME: Can't seem to get this to work.
        },
        cmdline_popup = {
            position = {
                row = 5,
                col = "50%",
            },
        },
        popupmenu = {
            relative = "editor",
            position = "auto",
        },
    },

    -- you can enable a preset for easier configuration
    presets = {
        bottom_search = false, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = true, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
    },
})
