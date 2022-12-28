local wk = require("which-key")

wk.register({
    -- Buffer switching
    ["1"] = { "<Cmd>BufferLineGoToBuffer 1<CR>", "which_key_ignore" },

    -- Common actions
    [" "] = { "<Cmd>Legendary<CR>", "Search All Commands" },

    -- Everything else
    b = {
        name = "buffer",
        ["<"] = { "<Cmd>edit #<CR>", "Previous Buffer" },
        b = { "<Cmd>Telescope buffers<CR>", "List Buffers" },
        c = { "<Cmd>Telescope git_bcommits<CR>", "List Buffers" },

        d = {
            name = "delete",
            a = { "<Cmd>BDelete all<CR>", "Delete All Buffers" },
            c = { "<Cmd>BufferLinePickClose<CR>", "Choose Buffer to Delete" },
            d = { "<Cmd>BDelete this<CR>", "Delete Current Buffer" },
            h = { "<Cmd>BDelete! hidden<CR>", "Delete Hidden Buffers" },
            n = { "<Cmd>BDelete nameless<CR>", "Delete All Nameless Buggers" },
            o = { "<Cmd>BDelete other<CR>", "Delete Other Buffers" },
            w = { "<Cmd>bufdo Bw<CR>", "Delete All Buffers, Keep Windows" },
        },

        m = { "<Cmd>messages<CR>", "Show 'messages' Buffer" },
        n = { "<Cmd>BufferLineCycleNext<CR>", "Next Buffer" },
        p = { "<Cmd>BufferLineCyclePrev<CR>", "Prev Buffer" },
        P = { "<Cmd>BufferLinePick<CR>", "Pick Buffer in Line" },
        N = { "<Cmd>enew<CR>", "New Empty Buffer" },
        y = { "<Cmd>%y<CR>", "Copy Buffer" },
        z = { "<Cmd>ZenMode<CR>", "Zen Mode" },
        S = { ":BufferLineSortByDirectory<CR>", "Sort Bufferline" },
    },
    c = {
        name = "code actions",
        s = { "<Cmd>lua vim.lsp.buf.code_action()<CR>", "Show Code Actions" }
    },
    e = {
        name = "errors/diagnostics",
        h = { "<Cmd>lua vim.diagnostic.open_float()<CR>", "Show Hover Diagnostic" },
        l = { "<Cmd>TroubleToggle document_diagnostics<CR>", "List current file Diagnostics" },
        n = { "<Cmd>lua vim.diagnostic.goto_next()<CR>", "Go to Next Diagnostic" },
        p = { "<Cmd>lua vim.diagnostic.goto_prev()<CR>", "Go to Prev Diagnostic" },

        L = { "<Cmd>TroubleToggle workspace_diagnostics<CR>", "List CWD Diagnstics" },
    },
    f = {
        name = "file",
        ["="] = { "<Cmd>LspZeroFormat<CR>", "Format Range/File" },
        f = {
            "<Cmd>Telescope find_files find_command=rg,--ignore-file-case-insensitive,--hidden,--files<CR>",
            "Find File",
        },
        s = { "<Cmd>w<CR>", "Save Current File" },
        S = { "<Cmd>wa<CR>", "Save All Open Files" },
        n = { "<Cmd>Telescope file_browser<CR>", "Open File Browser" },
        t = { "<Cmd>Neotree<CR>", "Show Neotree" },
        T = { "<Cmd>Neotree reveal", "Reveal Current File in Neotree" }
    },
    h = {
        name = "help",
        c = { "<Cmd>Legendary<CR>", "Search Legendary" },
        h = { "<Cmd>Telescope help_tags<CR>", "Search All Help Docs" },
        m = { "<Cmd>Telescope keymaps<CR>", "Search All Keymaps" },
        M = { "<Cmd>Telescope man_pages<CR>", "Search All Manpages" },
        H = { "<Cmd>Telescope highlights<CR>", "Search All Highlights" },
    },
    x = {
        name = "text",
        r = { "<Cmd>lua vim.lsp.buf.rename()<CR>", "Rename Symbol" }
    }

}, { prefix = "<leader>" })
