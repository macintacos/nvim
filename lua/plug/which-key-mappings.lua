local wk = require("which-key")

-- TODO: Need to figure out how to swap diagnostics with Trouble instead of CoC
-- TODO: Need to go through the rest of my old config, pull out things that I think I'll still use
-- TODO: Add keybindings for visualmulti - right now they show up in which-key but they don't have great labels

-- Main Mappings
wk.register({
    -- Buffer switching
    ["1"] = {"<Cmd>BufferGoto 1<CR>", "which_key_ignore"},
    ["2"] = {"<Cmd>BufferGoto 2<CR>", "which_key_ignore"},
    ["3"] = {"<Cmd>BufferGoto 3<CR>", "which_key_ignore"},
    ["4"] = {"<Cmd>BufferGoto 4<CR>", "which_key_ignore"},
    ["5"] = {"<Cmd>BufferGoto 5<CR>", "which_key_ignore"},
    ["6"] = {"<Cmd>BufferGoto 6<CR>", "which_key_ignore"},
    ["7"] = {"<Cmd>BufferGoto 7<CR>", "which_key_ignore"},
    ["8"] = {"<Cmd>BufferGoto 8<CR>", "which_key_ignore"},
    ["9"] = {"<Cmd>BufferLast<CR>",   "which_key_ignore"},

    -- Common actions
    ["!"] = {"<Cmd>call gtfo#open#term(getcwd(), '')<CR>",  "Open PWD in iTerm"},
    ["/"] = {"<Cmd>Telescope live_grep<CR>",                "Project Search"},
    [";"] = {"<Cmd>Commentary<CR>",                         "Toggle comment"},
    ["`"] = {"<Cmd>edit #<CR>",                             "Previous buffer"},
    ["<TAB>"] = {"<Cmd>bn<CR>",                             "Next buffer"},

    -- Everything Else
    b = {
        name = "buffer",
        b = {"<Cmd>Telescope buffers<CR>", "List Buffers"},
        c = {"<Cmd>Telescope git_bcommits<CR>", "List Buffers"},
        d = {
            name = "delete",
            a = {"<Cmd>Bdelete all<CR>", "Delete All Buffers"},
            d = {"<Cmd>BD<CR>", "Delete Current Buffer"},
            h = {"<Cmd>Bdelete hidden<CR>", "Delete Hidden Buffers"},
            o = {"<Cmd>Bdelete other<CR>", "Delete Other Buffers"},
            w = {"<Cmd>bufdo Bw<CR>", "Delete All Buffers, Keep Windows"},
        },
        m = {"<Cmd>messages<CR>", "Show 'messages' Buffer"},
        n = {"<Cmd>BufferNext<CR>", "Next Buffer"},
        N = {"<Cmd>enew<CR>", "New Empty Buffer"},
        p = {"<Cmd>BufferPrevious<CR>", "New Empty Buffer"},
        y = {"<Cmd>%y<CR>", "Copy Buffer"},
        z = {"<Cmd>ZenMode<CR>", "Zen Mode"},
        o = {"<Cmd>Vista coc<CR>", "Focus Outline"},
        s = {"<Cmd>Scratch<CR>", "Open Scratch Buffer"},
    },
    e = {
        name = "errors/diagnostics",
        l = {"<Cmd>CocList diagnostics<CR>", "List Diagnostics"},
        n = {"<Cmd>call CocAction('diagnosticNext')<CR>zz", "Next Diagnostic"},
        p = {"<Cmd>call CocAction('diagnosticPrevious')<CR>zz", "Prev Diagnostic"},
    },
    f = {
        name = "file",
        ['='] = {"<Cmd>Format<CR>", "Format File"},
        f = {"<Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>", "Find File"},
        t = {"<Cmd>CocCommand explorer<CR>", "Toggle Explorer"},
        e = {
            name = "edit",
            c = {"<Cmd>CocConfig<CR>",                                                 "Edit CoC Config"},
            d = {"<Cmd>cd $DOTFILES_HOME<CR><Cmd>Prosession .<CR><Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>", "Edit Dotfiles"},
            p = {"<Cmd>cd $NVIM_HOME<CR><Cmd>Prosession .<CR><Cmd>e $NVIM_HOME/lua/plugins.lua<CR>",                              "Edit Plugins"},
            w = {"<Cmd>cd $NVIM_HOME<CR><Cmd>Prosession .<CR><Cmd>e $NVIM_HOME/lua/plug/which-key-mappings.lua<CR>",              "Edit Which-Key Config"},
            S = {"<Cmd>PackerSync<CR>",                                                "Sync Packer"}
        },
        R = {"<Cmd>Move %<TAB>",             "Rename/Move Current File"},
        s = {"<Cmd>w<CR>",                   "Save Current File"},
        S = {"<Cmd>wa<CR>",                  "Save All Open Files"},
        o = {"<Cmd>FloatermNew ranger<CR>",  "Open File Browser"},
        O = {"<Cmd>Vista coc<CR>",           "Focus Symbol Outline"}
    },
    g = {
        name = "git",
        B = {"<Cmd>!smerge blame %<CR>",       "Blame Current Buffer in Sublime Merge"},
        b = {"<Cmd>Git blame<CR>",             "Blame Current Buffer"},
        c = {"<Cmd>Git commit<CR>",            "Commit Staged Changes"},
        d = {"<Cmd>Gdiffsplit<CR>",            "Diff Current Buffer in Split"},
        f = {"<Cmd>Git fetch<CR>",             "Fetch"},
        i = {"<Cmd>Octo issue list<CR>",       "List Issues in GitHub"},
        p = {"<Cmd>Git pull<CR>",              "Pull"},
        P = {"<Cmd>Octo pr list<CR>",          "List PRs in Current Repository"},
        s = {"<Cmd>!smerge .<CR><CR>",         "Status in Sublime Merge"},
        S = {"<Cmd>Telescope git_commits<CR>", "Search Git Commit History"}
    },

    h = {
        name = "help",
        c = {"<Cmd>Cheatsheet<CR>",          "Search Cheatsheet"},
        h = {"<Cmd>Telescope help_tags<CR>", "Search All Help Docs"},
        m = {"<Cmd>Telescope keymaps<CR>",   "Search All Keymaps"}
    },
    j = {
        name = "jump/join",
        i = {"<Cmd>Vista finder coc<CR>", "Jump to Symbol in File"},
        I = {"<Cmd>Vista finder!<CR>",    "Jump to Symbol in Project"},
        s = {"<Cmd>SplitjoinSplit<CR>",   "Splitjoin Split"},
        j = {"<Cmd>SplitjoinJoin<CR>",    "Splitjoin Join"}
    },
    o = {
        name = "open",
        d = {"<Cmd>TodoTrouble<CR>",  "Open TODO List"},
        f = {"gof",                   "Open File in Finder"},
        F = {"goF",                   "Open PWD in Finder"},
        t = {"got",                   "Open File Dir in iTerm"},
        T = {"goT",                   "Open PWD in iTerm"},
        q = {"<Cmd>Trouble quickfix", "Open Quickfix"},
    },
    p = {
        name = "project",
        p = {"<Cmd>Telescope zoxide list<CR>", "Open Project with Zoxide"}
    },
    q = {
        name = "quit",
        q = {"<Cmd>qa<CR>", "Quit All"}
    },
    s = {
        name = "search",
        b = {"<Cmd>lua require'telescope.builtin'.live_grep{grep_open_files = true}", "Search in Open Buffers"},
        g = {"<Cmd>Telescope git_commits",                                            "Search Git Commit History"},
        p = {"<Cmd>Telescope live_grep<CR>",                                          "Fuzzy Find Current Project"},
        s = {"<Cmd>Telescope current_buffer_fuzzy_find<CR>",                          "Fuzzy Find Current Buffer"},
    },
    t = {
        name = "toggles/themes",
        c = {"<Cmd>Telescope colorscheme<CR>",                "Choose Theme"},
        n = {"<Cmd>setlocal nonumber! norelativenumber!<CR>", "Toggle Line Numbers"},
        t = {"<Cmd>TodoTrouble<CR>",                          "Toggle TODOs"},
        p = {"<Cmd>AutoPairsToggle<CR>",                      "Toggle AutoPairs"},
        w = {"<Cmd>IndentBlanklineToggle<CR>",                "Toggle Whitespace"},
        W = {"<Cmd>setlocal nowrap!<CR>",                     "Toggle Word Wrap"},
        z = {"<Cmd>ZenMode<CR>",                              "Toggle Zen Mode"}
    },
    w = {
        name = "window",
        ["="] = {"<C-w>=",                          "Reset Window Layout"},
        ["-"] = {"<Cmd>rightbelow sb<CR>",          "Split Window Horizontal"},
        ["/"] = {"<Cmd>vertical rightbelow sb<CR>", "Split Window Vertical"},
        d = {"<Cmd>q<CR>",                          "Close Window"},
        m = {"<Cmd>ZoomWinTabToggle<CR>",           "Maximuze Buffer in Tab"},
        h = {"<C-w>h",                              "Focus Window to Left"},
        l = {"<C-w>l",                              "Focus Window to Right"},
        j = {"<C-w>j",                              "Focus Window Below"},
        k = {"<C-w>k",                              "Focus Window Above"},
        H = {"<Cmd>wincmd H<CR>",                   "Move Window to Right"},
        L = {"<Cmd>wincmd L<CR>",                   "Move Window to Left"},
        J = {"<Cmd>wincmd J<CR>",                   "Move Window to Bottom"},
        K = {"<Cmd>wincmd K<CR>",                   "Move Window to Top"},
        s = {"<Cmd>rightbelow sb<CR>",              "Split Window Horizontal"},
        t = {"<Cmd>enew<CR>",                       "New Empty Buffer"},
        v = {"<Cmd>vertical rightbelow sb<CR>",     "Split Window Vertical"},
        w = {"<Cmd>ChooseWin<CR>",                  "Choose Window"},

        f = {
            name = "file new window",
            l = {"<Cmd>vertical rightbelow sb<CR><Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>", "New File Split Right"},
            h = {"<Cmd>vertical sb<CR><Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>", "New File Split Left"},
            j = {"<Cmd>rightbelow sb<CR><Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>", "New File Split Below"},
            k = {"<Cmd>split<CR><Cmd>Telescope find_files find_command=rg,--ignore,--hidden,--files<CR>", "New File Split Above"},
        },

        N = {
            name = "new empty buffer",
            c = {"<Cmd>enew<CR>",                    "New In Current Window"},
            h = {"<Cmd>vnew<CR>",                    "New In Split Left"},
            l = {"<Cmd>vertical rightbelow new<CR>", "New In Split Right"},
            j = {"<Cmd>rightbelow new<CR>",          "New In Split Below"},
            k = {"<Cmd>new<CR>",                     "New In Split Above"},
        }
    },
    x = {
        name = "text",
        d = {"<Cmd>DogeGenerate<CR>", "Generate Documentation"}
    }
}, { prefix = "<leader>" })

vim.cmd([[
    autocmd FileType markdown lua which_key_markdown()
]])

_G.which_key_markdown = function()
    local buf = vim.api.nvim_get_current_buf()

    -- Normal Mappings
    wk.register({
        m = {
            name = "markdown",
            v = {"<Plug>MarkdownPreview", "Markdown Preview Start"},
            ["-"] = {"<Plug>(mkdx-checkbox-prev-n)", "Previous Checkbox State"},
            [","] = {"<Plug>(mkdx-tableize)", "CSV to Table"},
            ["="] = {"<Plug>(mkdx-checkbox-next-n)", "Next Checkbox State"},
            ["["] = {"<Plug>(mkdx-demote-header)", "Demote Header"},
            ["]"] = {"<Plug>(mkdx-promote-header)", "Promote Header"},
            ["{"] = {"<Plug>(mkdx-prev-section)", "Previous Section"},
            ["}"] = {"<Plug>(mkdx-next-section)", "Next Section"},
            ["`"] = {"<Plug>(mkdx-text-inline-code-n)", "Inline Code"},
            ["'"] = {"<Plug>(mkdx-toggle-quote-n)", "Toggle Quotes"},
            T = {"<Plug>(mkdx-gen-or-upd-toc)", "Generate/Update ToC"},
            b = {"<Plug>(mkdx-text-bold-n)", "Bold Text"},
            i = {"<Plug>(mkdx-text-italic-n)", "Italicize Text"},
            j = {"<Cmd>Telescope heading<CR>", "Jump to Header"},
            k = {"<Plug>(mkdx-wrap-link-n)", "Link Text"},
            t = {"<Plug>(mkdx-toggle-checkbox-n)", "Toggle Checkbox"},
            l = {
                name = "lists",
                l = {"<Plug>(mkdx-toggle-list-n)", "Toggle List Item"},
                c = {"<Plug>(mkdx-toggle-checklist-n)", "Toggle Checklist Item"},
            }
        }
    },{ prefix = "<localleader>", buffer = buf, noremap = false })

    -- Visual Mappings
    wk.register({
        m = {
            ["'"] = {"<Plug>(mkdx-toggle-quote-v)", "Toggle Quotes"},
            [","] = {"<Plug>(mkdx-tableize)", "CSV to Table"},
            ["-"] = {"<Plug>(mkdx-checkbox-prev-v)", "Previous Checkbox State"},
            ["="] = {"<Plug>(mkdx-checkbox-next-v)", "Next Checkbox State"},
            ["`"] = {"<Plug>(mkdx-text-inline-code-v)", "Wrap Code Inline"},
            k = {"<Plug>(mkdx-wrap-link-v)", "Link Text"},
            b = {"<Plug>(mkdx-text-bold-v)", "Bold Text"},
            i = {"<Plug>(mkdx-text-italic-v)", "Italicize Text"},
            t = {"<Plug>(mkdx-toggle-checkbox-v)", "Toggle Checkbox"},
            l = {
                name = "lists",
                l = {"<Plug>(mkdx-toggle-list-v)", "Toggle List Item"},
                c = {"<Plug>(mkdx-toggle-checklist-v)", "Toggle Checklist Item"},
            }
        }
    }, { prefix = "<localleader>", buffer = buf, mode = "v", noremap = false})
end
