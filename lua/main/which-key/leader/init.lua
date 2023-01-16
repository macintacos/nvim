local wk = require("which-key")
local cmd = require("main.helpers").cmd

-- Load configs at this level
require("main.which-key.leader.visual")
require("main.which-key.leader.neo-tree")

-- "General" <leader> maps
wk.register({
    -- Buffer switching
    ["1"] = { "<Plug>(cokeline-focus-1)", "which_key_ignore" },
    ["2"] = { "<Plug>(cokeline-focus-2)", "which_key_ignore" },
    ["3"] = { "<Plug>(cokeline-focus-3)", "which_key_ignore" },
    ["4"] = { "<Plug>(cokeline-focus-4)", "which_key_ignore" },
    ["5"] = { "<Plug>(cokeline-focus-5)", "which_key_ignore" },
    ["6"] = { "<Plug>(cokeline-focus-6)", "which_key_ignore" },
    ["7"] = { "<Plug>(cokeline-focus-7)", "which_key_ignore" },
    ["8"] = { "<Plug>(cokeline-focus-8)", "which_key_ignore" },
    ["9"] = { "<Plug>(cokeline-focus-9)", "which_key_ignore" },

    -- Common actions
    [" "] = { cmd("Legendary"), "Search All Commands" },
    ["!"] = { cmd("normal goT"), "Open PWD in iTerm" },
    ["?"] = { cmd("normal goT"), "Open PWD in iTerm" },
    ["/"] = { cmd("FzfLua live_grep"), "Search Project" },
    [";"] = { cmd("normal gcc"), "Toggle Comment" },
    ["`"] = { "<Plug>(cokeline-focus-next)", "Go to Next Buffer" },
    ["~"] = { "<Plug>(cokeline-focus-prev)", "Go to Prev Buffer" },
    ["<TAB>"] = { cmd("edit #"), "Previously Edited Buffer" },

    -- Everything else
    b = {
        name = "buffer",
        ["<"] = { cmd("edit #"), "Go to Last Buffer" },
        b = { cmd("FzfLua buffers"), "List Buffers" },
        c = { cmd("FzfLua git_bcommits"), "List Commits for Buffer" },
        d = {
            name = "delete",
            a = { cmd("BDelete all"), "Delete All Buffers" },
            c = { "<Plug>(cokeline-pick-close)", "Choose Buffer to Delete" },
            d = {
                cmd("lua require('close_buffers').delete({ type = 'this' })"),
                "Delete Current Buffer",
            },
            h = {
                cmd(
                    "lua require('close_buffers').delete({ type = 'hidden', force = true })"
                ),
                "Delete Hidden Buffers",
            },
            n = {
                cmd("lua require('close_buffers').delete({ type = 'nameless' })"),
                "Delete All Nameless Buffers",
            },
            o = { cmd("BDelete other"), "Delete Other Buffers" },
            w = { cmd("bufdo Bw"), "Delete All Buffers, Keep Windows" },
        },
        m = { cmd("messages"), "Show 'messages' Buffer" },
        n = { "<Plug>(cokeline-focus-next)", "Next Buffer" },
        p = { "<Plug>(cokeline-focus-next)", "Prev Buffer" },
        P = { "<Plug>(cokeline-pick-focus)", "Pick Buffer in Line" },
        N = { cmd("enew"), "New Empty Buffer" },
        y = { cmd("%y"), "Copy Buffer" },
        z = { cmd("ZenMode"), "Zen Mode" },
    },
    c = {
        name = "code actions",
        s = { cmd("lua vim.lsp.buf.code_action()"), "Show Code Actions" },
    },
    e = {
        name = "errors/diagnostics",
        h = { cmd("lua vim.diagnostic.open_float()"), "Show Hover Diagnostic" },
        l = {
            cmd("TroubleToggle document_diagnostics"),
            "List current file Diagnostics",
        },
        n = { cmd("lua vim.diagnostic.goto_next()"), "Go to Next Diagnostic" },
        p = { cmd("lua vim.diagnostic.goto_prev()"), "Go to Prev Diagnostic" },
        L = { cmd("TroubleToggle workspace_diagnostics"), "List CWD Diagnstics" },
    },
    f = {
        name = "file",
        ["="] = { cmd("LspZeroFormat"), "Format Range/File" },
        f = { cmd("FzfLua files"), "Find File" },
        s = { cmd("w"), "Save Current File" },
        S = { cmd("wa"), "Save All Open Files" },
        n = {
            cmd("Telescope file_browser initial_mode=normal"),
            "Open File Browser",
        },
        t = { cmd("Neotree"), "Show Neotree" },
        T = { cmd("Neotree reveal"), "Reveal Current File in Neotree" },
    },
    g = {
        name = "git",
        B = { cmd("!smerge blame %"), "Blame Current Buffer in Sublime Merge" },
        b = { cmd("Git blame"), "Blame Current Buffer" },
        c = { cmd("Git commit"), "Commit Staged Changes" },
        C = { "<Cmd>FzfLua git_branches" },
        d = { cmd("DiffInlineFile"), "Diff Current Buffer" }, -- Custom command in diffview.vim
        D = { cmd("DiffviewOpen"), "Diff Working Tree" },
        f = { cmd("Git fetch"), "Fetch" },
        G = {
            name = "GitHub",
            b = { cmd("Octo repo browser"), "Open repo in browser" },
            g = { cmd("Octo gist list"), "List gists" },
            i = { cmd("Octo issue list"), "List Issues in GitHub" },
            p = { cmd("Octo pr list"), "List PRs in Current Repository" },
            P = { cmd("Octo pr browser"), "List PRs in Current Repository" },
        },
        l = { cmd("Git pull"), "Pull" },
        P = { cmd("Git push"), "Push" },
        s = { cmd("LazyGit"), "Open LazyGit" },
        S = { cmd("!smerge ."), "Status in Sublime Merge" },
    },
    h = {
        name = "help",
        c = { cmd("Legendary"), "Search Legendary" },
        h = { cmd("FzfLua help_tags"), "Search All Help Docs" },
        m = { cmd("FzfLua keymaps"), "Search All Keymaps" },
        M = { cmd("FzfLua man_pages"), "Search All Manpages" },
        H = { cmd("FzfLua highlights"), "Search All Highlights" },
    },
    j = {
        name = "jump/join",
        i = { cmd("FzfLua lsp_document_symbols"), "Jump to Symbol in File" },
        I = {
            cmd("FzfLua lsp_dynamic_workspace_symbols"),
            "Jump to Symbol in Workspace",
        },
        s = { cmd("SplitjoinSplit"), "Splitjoin Split" },
        j = { cmd("SplitjoinJoin"), "Splitjoin Join" },
    },
    o = {
        name = "open",
        d = { cmd("TodoTrouble"), "Open TODO List (Trouble)" },
        D = { cmd("TodoTelescope"), "Open TODO List (Telescope)" },
        f = { cmd("normal gof"), "Open File in Finder" },
        F = { cmd("normal goF"), "Open PWD in Finder" },
        s = { cmd("SymbolsOutline"), "Show Symbols Outline" },
        t = { cmd("normal got"), "Open File Dir in iTerm" },
        T = { cmd("normal goT"), "Open PWD in iTerm" },
        q = { cmd("Trouble quickfix"), "Open Quickfix" },
    },
    q = {
        name = "quit",
        q = { cmd("qa"), "Quit All" },
    },
    s = {
        name = "search/show",
        b = {
            cmd("lua require'telescope.builtin'.live_grep{grep_open_files = true}"),
            "Search in Open Buffers",
        },
        g = { cmd("FzfLua git_commits"), "Search Git Commit History" },
        p = { cmd("FzfLua live_grep"), "Fuzzy Find Current Project" },
        s = {
            cmd("FzfLua lgrep_curbuf"),
            "Fuzzy Find Current Buffer",
        },
    },
    t = {
        name = "toggles",
        c = { cmd("FzfLua colorscheme"), "Choose Theme" },
        n = { cmd("setlocal nonumber! norelativenumber!"), "Toggle Line Numbers" },
        t = { cmd("TodoTrouble"), "Toggle TODOs" },
        p = { cmd("AutoPairsToggle"), "Toggle AutoPairs" },
        w = { cmd("setlocal nowrap!"), "Toggle Word Wrap" },
        z = { cmd("ZenMode"), "Toggle Zen Mode" },
    },
    w = {
        name = "window",
        ["="] = { "<C-w>=", "Reset Window Layout" },
        ["-"] = { cmd("rightbelow sb"), "Split Window Horizontal" },
        ["/"] = { cmd("vertical rightbelow sb"), "Split Window Vertical" },
        d = { cmd("q"), "Close Current Window" },
        D = { cmd("only"), "Close All Other Windows" },
        h = { "<C-w>h", "Focus Window to Left" },
        l = { "<C-w>l", "Focus Window to Right" },
        j = { "<C-w>j", "Focus Window Below" },
        k = { "<C-w>k", "Focus Window Above" },
        H = { cmd("wincmd H"), "Move Window to Right" },
        L = { cmd("wincmd L"), "Move Window to Left" },
        J = { cmd("wincmd J"), "Move Window to Bottom" },
        K = { cmd("wincmd K"), "Move Window to Top" },
        m = { cmd("ZenMode"), "Zen Mode" },
        s = { cmd("rightbelow sb"), "Split Window Horizontal" },
        t = { cmd("enew"), "New Empty Buffer" },
        T = {
            name = "tabs",
            d = { cmd("tabclose"), "Close Current Tab" },
        },
        v = { cmd("vertical rightbelow sb"), "Split Window Vertical" },
        f = {
            name = "file new window",
            l = {
                cmd("vertical rightbelow sb<CR><Cmd>FzfLua files"),
                "New File Split Right",
            },
            h = { cmd("vertical sb<CR><Cmd>FzfLua files"), "New File Split Left" },
            j = {
                cmd("rightbelow sb<CR><Cmd>FzfLua files"),
                "New File Split Below",
            },
            k = { cmd("split<CR><Cmd>FzfLua files"), "New File Split Above" },
        },
        N = {
            name = "new empty buffer",
            c = { cmd("enew"), "New In Current Window" },
            h = { cmd("vnew"), "New In Split Left" },
            l = { cmd("vertical rightbelow new"), "New In Split Right" },
            j = { cmd("rightbelow new"), "New In Split Below" },
            k = { cmd("new"), "New In Split Above" },
        },
    },
    u = {
        name = "undo",
        t = { cmd("UndotreeShow<CR><Cmd>UndotreeFocus"), "Toggle Undotree" },
    },
    x = {
        name = "text",
        r = {
            function()
                return ":IncRename " .. vim.fn.expand("<cword>")
            end,
            "Rename Symbol",
            expr = true,
        },
    },
}, { prefix = "<leader>" })
