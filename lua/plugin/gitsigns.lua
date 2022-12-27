local colors
if vim.g.background == "light" then
    colors = require("plugin.global_colors").light
else
    colors = require("plugin.global_colors").dark
end

require("gitsigns").setup({
    current_line_blame = true,
    current_line_blame_formatter = function(name, blame_info)
        if blame_info.author == name then
            blame_info.author = "You"
        end

        local text
        if blame_info.author == "Not Committed Yet" then
            text = blame_info.author
        else
            text = string.format(
                "%s, %s - %s",
                blame_info.author,
                os.date("%Y-%m-%d", tonumber(blame_info["author_time"])),
                blame_info.summary
            )
        end

        return { { "   " .. text, "GitSignsCurrentLineBlame" } }
    end,
})
