return {
  "jake-stewart/multicursor.nvim",
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { link = "Cursor" })
    hl(0, "MultiCursorVisual", { link = "Visual" })
    hl(0, "MultiCursorSign", { link = "SignColumn" })
    hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
    hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
    hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
  end,
  keys = function()
    local mc = require("multicursor-nvim")

    return {
      -- stylua: ignore start

      -- Add cursors above or below
      { "<C-k>", function() mc.lineAddCursor(-1) end, mode = { "n", "v" } },
      { "<C-j>", function() mc.lineAddCursor(1)  end, mode = { "n", "v" } },

      -- Add or skip cursor above/below the main cursor
      { "<C-S-j>", function() mc.lineAddCursor(1)  end, mode = { "n", "v" } },
      { "<C-S-k>", function() mc.lineAddCursor(-1)  end, mode = { "n", "v" } },

      -- Add cursors to match
      { "<C-n>",   function() mc.matchAddCursor(1)  end, mode = { "n", "v" } },
      { "<C-S-n>", function() mc.matchAddCursor(-1) end, mode = { "n", "v" } },
      { "gn",      function() mc.matchAddCursor(1)  end, mode = { "n", "v" } },
      { "gN",      function() mc.matchAddCursor(-1) end, mode = { "n", "v" } },

      -- Align all cursors
      { "ga", function() mc.alignCursors() end, mode = { "n" } },

      -- All all matches in the document
      { "gA", function() mc.matchAllAddCursors() end, mode = { "n", "v" } },

      -- Rotate the main cursor.
      { "<C-l>", function() mc.nextCursor() end , mode = { "n", "v" } },
      { "<C-h>", function() mc.prevCursor() end , mode = { "n", "v" } },

      -- Add and remove cursors with control + left click.
      { "<C-leftmouse>", function() mc.handleMouse() end , mode = { "n", "v" } },

      -- Easy way to add and remove cursors using the main cursor.
      { "gb", function() mc.toggleCursor() end , mode = { "n", "v" } },

      -- Clone every cursor and disable the originals.
      { "gB", function() mc.duplicateCursors() end , mode = { "n", "v" } },

      -- Append/insert for each line of visual selections.
      { "I", function() mc.insertVisual() end , mode = { "v" } },
      { "A", function() mc.appendVisual() end , mode = { "v" } },

      -- Bring back cursors if you accidentally clear them
      { "gV", function() mc.restoreCursors() end, mode = { "n" } },

      -- Jumplist support
      { "<c-i>", function() mc.jumpForward()  end, mode = { "v", "n" } },
      { "<c-o>", function() mc.jumpBackward() end, mode = { "v", "n" } },

      -- Use ESC to handle cursor clearing
      {
        "<Esc>",
        function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          elseif mc.hasCursors() then
            mc.clearCursors()
          else
            -- We do this to account for Flash's cursor weirdness
            require("flash.repeat").get_state("jump"):hide()
                local c = require("flash.plugins.char")
                c.jumping = false
                if c.state then
                    c.state:hide()
                end
                c.state = nil
                c.jump_labels = false
                vim.cmd.noh()
          end
        end,
        mode = { "n", "v" },
      },

      --[[ Disabled functionality, kept for reference ]]

      -- You can also add cursors with any motion you prefer:
      -- { "<Right>",         function() mc.addCurosor("w")  end, mode = { "n" } },
      -- { "<Leader><Right>", function() mc.skipCurosor("w") end, mode = { "n" } },

      -- Delete the main cursor.
      -- { "<leader>x", mc.deleteCursor() end, mode = { "n", "v" } }

      -- Split visual selections by regex.
      -- { S", function() mc.splitCursors() end, mode = { "v" } }

      -- match new cursors within visual selections by regex.
      -- { "M", function() mc.matchCursors() end, mode = { "v" } }

      -- Rotate visual selection contents.
      -- { "<leader>t", function() mc.transposeCursors(1) end, mode = { "v" } }
      -- { "<leader>T", function() mc.transposeCursors(-1) end, mode = { "v" } }

      -- stylua: ignore end
    }
  end,
}
