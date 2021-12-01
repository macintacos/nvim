The vim.cmd() calls take care of specifying a global field that we can then call in subsequent which-key definitions.

The language is meant to be found by calling it like this:

```lua
local wk = require("which-key")

vim.cmd([[autocmd FileType markdown lua which_key_markdown()]])

_G.which_key_markdown = function()
    local buf = vim.api.nvim_get_current_buf()

    wk.register(
            { --[[ definitions here ]] },
            { prefix ="<localleader>", buffer = buf, noremap = true }
        )
end
```

Don't get me wrong - this is brittle, but this was the easiest way to break out things. I'm just too lazy to figure out something better.
