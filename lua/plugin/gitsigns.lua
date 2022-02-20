local hi = vim.highlight.create
local global_colors = require("plugin.global_colors")

require("gitsigns").setup {
    current_line_blame = true,
    current_line_blame_formatter = function(name, blame_info)
          if blame_info.author == name then
            blame_info.author = 'You'
          end

          local text
          if blame_info.author == 'Not Committed Yet' then
            text = blame_info.author
          else
            text = string.format(
              '%s, %s - %s',
              blame_info.author,
              os.date('%Y-%m-%d', tonumber(blame_info['author_time'])),
              blame_info.summary
            )
          end

          return {{'   '..text, 'GitSignsCurrentLineBlame'}}
        end
}

-- Appearance
hi("GitSignsCurrentLineBlame", {guifg = global_colors.comments}, false)
