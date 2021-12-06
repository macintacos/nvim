local wk = require("which-key")

_G.which_key_markdown = function()
    local buf = vim.api.nvim_get_current_buf()

    -- Normal Mappings
    wk.register({
        name = "markdown",
        v = { "<Plug>MarkdownPreview", "Markdown Preview Start" },
        V = { "<Cmd>Glow %<CR>", "Glow Preview" },
        ["-"] = { "<Plug>(mkdx-checkbox-prev-n)", "Previous Checkbox State" },
        [","] = { "<Plug>(mkdx-tableize)", "CSV to Table" },
        ["="] = { "<Plug>(mkdx-checkbox-next-n)", "Next Checkbox State" },
        ["["] = { "<Plug>(mkdx-demote-header)", "Demote Header" },
        ["]"] = { "<Plug>(mkdx-promote-header)", "Promote Header" },
        ["{"] = { "<Plug>(mkdx-prev-section)", "Previous Section" },
        ["}"] = { "<Plug>(mkdx-next-section)", "Next Section" },
        ["`"] = { "<Plug>(mkdx-text-inline-code-n)", "Inline Code" },
        ["'"] = { "<Plug>(mkdx-toggle-quote-n)", "Toggle Quotes" },
        T = { "<Plug>(mkdx-gen-or-upd-toc)", "Generate/Update ToC" },
        b = { "<Plug>(mkdx-text-bold-n)", "Bold Text" },
        i = { "<Plug>(mkdx-text-italic-n)", "Italicize Text" },
        j = { "<Cmd>Telescope heading<CR>", "Jump to Header" },
        k = { "<Plug>(mkdx-wrap-link-n)", "Link Text" },
        t = { "<Plug>(mkdx-toggle-checkbox-n)", "Toggle Checkbox" },

        l = {
            name = "lists",
            l = { "<Plug>(mkdx-toggle-list-n)", "Toggle List Item" },
            c = { "<Plug>(mkdx-toggle-checklist-n)", "Toggle Checklist Item" },
        },
    }, { prefix = "<localleader>", buffer = buf, noremap = false })

    -- Visual Mappings
    wk.register({
        ["'"] = { "<Plug>(mkdx-toggle-quote-v)", "Toggle Quotes" },
        [","] = { "<Plug>(mkdx-tableize)", "CSV to Table" },
        ["-"] = { "<Plug>(mkdx-checkbox-prev-v)", "Previous Checkbox State" },
        ["="] = { "<Plug>(mkdx-checkbox-next-v)", "Next Checkbox State" },
        ["`"] = { "<Plug>(mkdx-text-inline-code-v)", "Wrap Code Inline" },
        k = { "<Plug>(mkdx-wrap-link-v)", "Link Text" },
        b = { "<Plug>(mkdx-text-bold-v)", "Bold Text" },
        i = { "<Plug>(mkdx-text-italic-v)", "Italicize Text" },
        t = { "<Plug>(mkdx-toggle-checkbox-v)", "Toggle Checkbox" },
        t = { "<Plug>(mkdx-toggle-checkbox-v)", "Toggle Checkbox" },

        l = {
            name = "lists",
            l = { "<Plug>(mkdx-toggle-list-v)", "Toggle List Item" },
            c = { "<Plug>(mkdx-toggle-checklist-v)", "Toggle Checklist Item" },
        },
    }, { prefix = "<localleader>", buffer = buf, mode = "v", noremap = false })
end
