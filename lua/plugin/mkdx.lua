-- Ref: https://github.com/SidOfc/mkdx
-- TODO: Take a closer look at the options that mkdx provides

vim.g["mkdx#settings.restore_visual"] =  true
vim.g["mkdx#settings.map.enable"] =  true

vim.g.markdown_fenced_languages = {
    "lua", "html", "javascript", "typescript", "python", "bash"
}
vim.g.markdown_syntax_conceal = false
