-- For multicursor.nvim status when active
local function is_active()
    local ok, hydra = pcall(require, "hydra.statusline")
    return ok and hydra.is_active()
end

local function get_name()
    local ok, hydra = pcall(require, "hydra.statusline")
    if ok then
        return hydra.get_name()
    end
    return ""
end

require("lualine").setup({
    options = {
        globalstatus = true,
    },
    sections = {
        lualine_b = {
            { get_name, cond = is_active },
        },
        lualine_x = {
            {
                require("lazy.status").updates,
                cond = require("lazy.status").has_updates,
                color = { fg = "#ff9e64" },
            },
            {
                require("recorder").recordingStatus(),
            },
        },
    },
})
