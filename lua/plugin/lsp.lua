local lsp_installer = require("nvim-lsp-installer")

lsp_installer.on_server_ready(function(server)
    require("lsp_signature").setup({
        floating_window_above_cur_line = true,
        handler_opts = {
            border = 'single'
        },
        transparency = 1
    })
end)


-- local signs = {
--     Error = " ",
--     Warning = " ",
--     Hint = " ",
--     Information = " "
-- }
-- for type, icon in pairs(signs) do
--     local hl = "LspDiagnosticsSign" .. type
--     vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = hl})
-- end


