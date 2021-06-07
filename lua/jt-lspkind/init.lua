-- TODO: Pick different icons, use octicons or something
require("lspkind").init({
    with_text = true,
    preset = "default", -- ref: https://github.com/onsails/lspkind-nvim/issues/6
    symbol_map = {
        Class = '',
        Color = '',
        Constant = '',
        Constructor = '',
        Enum = '了',
        EnumMember = '',
        File = '',
        Folder = '',
        Function = '',
        Interface = 'ﰮ',
        Keyword = '',
        Method = 'ƒ',
        Module = '',
        Property = '',
        Snippet = '﬌',
        Struct = '',
        Text = '',
        Unit = '',
        Value = '',
        Variable = '',
    }
})
