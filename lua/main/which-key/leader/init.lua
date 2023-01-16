local wk = require("which-key")

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
    [" "] = { "<Cmd>Legendary<CR>", "Search All Commands" },
    ["!"] = { ":normal goT<CR>", "Open PWD in iTerm" },
    ["?"] = { ":normal goT<CR>", "Open PWD in iTerm" },
    ["/"] = { "<Cmd>FzfLua live_grep<CR>", "Search Project" },
    [";"] = { ":normal gcc<CR>", "Toggle Comment" },
    ["`"] = { "<Plug>(cokeline-focus-next)", "Go to Next Buffer" },
    ["~"] = { "<Plug>(cokeline-focus-prev)", "Go to Prev Buffer" },
    ["<TAB>"] = { "<Cmd>edit #<CR>", "Previously Edited Buffer" },

    -- Everything else
    b = {
        name = "buffer",
        ["<"] = { "<Cmd>edit #<CR>", "Go to Last Buffer" },
        b = { "<Cmd>FzfLua buffers<CR>", "List Buffers" },
        c = { "<Cmd>FzfLua git_bcommits<CR>", "List Commits for Buffer" },
        d = {
            name = "delete",
            a = { "<Cmd>BDelete all<CR>", "Delete All Buffers" },
            c = { "<Plug>(cokeline-pick-close)", "Choose Buffer to Delete" },
            d = {
                "<Cmd>lua require('close_buffers').delete({ type = 'this' })<CR>",
                "Delete Current Buffer",
            },
            h = {
                "<Cmd>lua require('close_buffers').delete({ type = 'hidden', force = true })<CR>",
                "Delete Hidden Buffers",
            },
            n = {
                "<Cmd>lua require('close_buffers').delete({ type = 'nameless' })<CR>",
                "Delete All Nameless Buffers",
            },
            o = { "<Cmd>BDelete other<CR>", "Delete Other Buffers" },
            w = { "<Cmd>bufdo Bw<CR>", "Delete All Buffers, Keep Windows" },
        },
        m = { "<Cmd>messages<CR>", "Show 'messages' Buffer" },
        n = { "<Plug>(cokeline-focus-next)", "Next Buffer" },
        p = { "<Plug>(cokeline-focus-next)", "Prev Buffer" },
        P = { "<Plug>(cokeline-pick-focus)", "Pick Buffer in Line" },
        N = { "<Cmd>enew<CR>", "New Empty Buffer" },
        y = { "<Cmd>%y<CR>", "Copy Buffer" },
        z = { "<Cmd>ZenMode<CR>", "Zen Mode" },
    },
    c = {
        name = "code actions",
        s = { "<Cmd>lua vim.lsp.buf.code_action()<CR>", "Show Code Actions" },
    },
    e = {
        name = "errors/diagnostics",
        h = { "<Cmd>lua vim.diagnostic.open_float()<CR>", "Show Hover Diagnostic" },
        l = {
            "<Cmd>TroubleToggle document_diagnostics<CR>",
            "List current file Diagnostics",
        },
        n = { "<Cmd>lua vim.diagnostic.goto_next()<CR>", "Go to Next Diagnostic" },
        p = { "<Cmd>lua vim.diagnostic.goto_prev()<CR>", "Go to Prev Diagnostic" },
        L = { "<Cmd>TroubleToggle workspace_diagnostics<CR>", "List CWD Diagnstics" },
    },
    f = {
        name = "file",
        ["="] = { "<Cmd>LspZeroFormat<CR>", "Format Range/File" },
        f = { "<Cmd>FzfLua files<CR>", "Find File" },
        s = { "<Cmd>w<CR>", "Save Current File" },
        S = { "<Cmd>wa<CR>", "Save All Open Files" },
        n = {
            "<Cmd>Telescope file_browser initial_mode=normal<CR>",
            "Open File Browser",
        },
        t = { "<Cmd>Neotree<CR>", "Show Neotree" },
        T = { "<Cmd>Neotree reveal<CR>", "Reveal Current File in Neotree" },
    },
    g = {
        name = "git",
        B = { "<Cmd>!smerge blame %<CR>", "Blame Current Buffer in Sublime Merge" },
        b = { "<Cmd>Git blame<CR>", "Blame Current Buffer" },
        c = { "<Cmd>Git commit<CR>", "Commit Staged Changes" },
        C = { "<Cmd>FzfLua git_branches" },
        d = { "<Cmd>DiffInlineFile<CR>", "Diff Current Buffer" }, -- Custom command in diffview.vim
        D = { "<Cmd>DiffviewOpen<CR>", "Diff Working Tree" },
        f = { "<Cmd>Git fetch<CR>", "Fetch" },
        G = {
            name = "GitHub",
            b = { "<Cmd>Octo repo browser<CR>", "Open repo in browser" },
            g = { "<Cmd>Octo gist list<CR>", "List gists" },
            i = { "<Cmd>Octo issue list<CR>", "List Issues in GitHub" },
            p = { "<Cmd>Octo pr list<CR>", "List PRs in Current Repository" },
            P = { "<Cmd>Octo pr browser<CR>", "List PRs in Current Repository" },
        },
        l = { "<Cmd>Git pull<CR>", "Pull" },
        P = { "<Cmd>Git push<CR>", "Push" },
        s = { "<Cmd>LazyGit<CR>", "Open LazyGit" },
        S = { "<Cmd>!smerge .<CR>", "Status in Sublime Merge" },
    },
    h = {
        name = "help",
        c = { "<Cmd>Legendary<CR>", "Search Legendary" },
        h = { "<Cmd>FzfLua help_tags<CR>", "Search All Help Docs" },
        m = { "<Cmd>FzfLua keymaps<CR>", "Search All Keymaps" },
        M = { "<Cmd>FzfLua man_pages<CR>", "Search All Manpages" },
        H = { "<Cmd>FzfLua highlights<CR>", "Search All Highlights" },
    },
    j = {
        name = "jump/join",
        i = { "<Cmd>FzfLua lsp_document_symbols<CR>", "Jump to Symbol in File" },
        I = {
            "<Cmd>FzfLua lsp_dynamic_workspace_symbols<CR>",
            "Jump to Symbol in Workspace",
        },
        s = { "<Cmd>SplitjoinSplit<CR>", "Splitjoin Split" },
        j = { "<Cmd>SplitjoinJoin<CR>", "Splitjoin Join" },
    },
    o = {
        name = "open",
        d = { "<Cmd>TodoTrouble<CR>", "Open TODO List (Trouble)" },
        D = { "<Cmd>TodoTelescope<CR>", "Open TODO List (Telescope)" },
        f = { ":normal gof<CR>", "Open File in Finder" },
        F = { ":normal goF<CR>", "Open PWD in Finder" },
        s = { "<Cmd>SymbolsOutline<CR>", "Show Symbols Outline" },
        t = { ":normal got<CR>", "Open File Dir in iTerm" },
        T = { ":normal goT<CR>", "Open PWD in iTerm" },
        q = { "<Cmd>Trouble quickfix<CR>", "Open Quickfix" },
    },
    q = {
        name = "quit",
        q = { "<Cmd>qa<CR>", "Quit All" },
    },
    s = {
        name = "search/show",
        b = {
            "<Cmd>lua require'telescope.builtin'.live_grep{grep_open_files = true}<CR>",
            "Search in Open Buffers",
        },
        g = { "<Cmd>FzfLua git_commits", "Search Git Commit History" },
        p = { "<Cmd>FzfLua live_grep<CR>", "Fuzzy Find Current Project" },
        s = {
            "<Cmd>FzfLua lgrep_curbuf<CR>",
            "Fuzzy Find Current Buffer",
        },
    },
    t = {
        name = "toggles",
        c = { "<Cmd>FzfLua colorscheme<CR>", "Choose Theme" },
        n = { "<Cmd>setlocal nonumber! norelativenumber!<CR>", "Toggle Line Numbers" },
        t = { "<Cmd>TodoTrouble<CR>", "Toggle TODOs" },
        p = { "<Cmd>AutoPairsToggle<CR>", "Toggle AutoPairs" },
        w = { "<Cmd>setlocal nowrap!<CR>", "Toggle Word Wrap" },
        z = { "<Cmd>ZenMode<CR>", "Toggle Zen Mode" },
    },
    w = {
        name = "window",
        ["="] = { "<C-w>=", "Reset Window Layout" },
        ["-"] = { "<Cmd>rightbelow sb<CR>", "Split Window Horizontal" },
        ["/"] = { "<Cmd>vertical rightbelow sb<CR>", "Split Window Vertical" },
        d = { "<Cmd>q<CR>", "Close Current Window" },
        D = { "<Cmd>only<CR>", "Close All Other Windows" },
        h = { "<C-w>h", "Focus Window to Left" },
        l = { "<C-w>l", "Focus Window to Right" },
        j = { "<C-w>j", "Focus Window Below" },
        k = { "<C-w>k", "Focus Window Above" },
        H = { "<Cmd>wincmd H<CR>", "Move Window to Right" },
        L = { "<Cmd>wincmd L<CR>", "Move Window to Left" },
        J = { "<Cmd>wincmd J<CR>", "Move Window to Bottom" },
        K = { "<Cmd>wincmd K<CR>", "Move Window to Top" },
        m = { "<Cmd>ZenMode<CR>", "Zen Mode" },
        s = { "<Cmd>rightbelow sb<CR>", "Split Window Horizontal" },
        t = { "<Cmd>enew<CR>", "New Empty Buffer" },
        T = {
            name = "tabs",
            d = { "<Cmd>tabclose<CR>", "Close Current Tab" },
        },
        v = { "<Cmd>vertical rightbelow sb<CR>", "Split Window Vertical" },
        f = {
            name = "file new window",
            l = { "<Cmd>vertical rightbelow sb<CR><Cmd>FzfLua files<CR>", "New File Split Right"},
            h = { "<Cmd>vertical sb<CR><Cmd>FzfLua files<CR>", "New File Split Left" },
            j = { "<Cmd>rightbelow sb<CR><Cmd>FzfLua files<CR>", "New File Split Below" },
            k = { "<Cmd>split<CR><Cmd>FzfLua files<CR>", "New File Split Above" },
        },
        N = {
            name = "new empty buffer",
            c = { "<Cmd>enew<CR>", "New In Current Window" },
            h = { "<Cmd>vnew<CR>", "New In Split Left" },
            l = { "<Cmd>vertical rightbelow new<CR>", "New In Split Right" },
            j = { "<Cmd>rightbelow new<CR>", "New In Split Below" },
            k = { "<Cmd>new<CR>", "New In Split Above" },
        },
    },
    u = {
        name = "undo",
        t = { "<Cmd>UndotreeShow<CR><Cmd>UndotreeFocus<CR>", "Toggle Undotree" }
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
