-- Completion engine
return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    -- More sources
    { "hrsh7th/cmp-cmdline" },
    { "hrsh7th/cmp-nvim-lua" },
    { "ray-x/cmp-treesitter" },
    { "rasulomaroff/cmp-bufname" },
    { "mtoohey31/cmp-fish", ft = "fish" },
    { "PhilippFeO/cmp-csv" },
    { "dmitmel/cmp-cmdline-history" },
    { "davidsierradz/cmp-conventionalcommits" },
    { "petertriho/cmp-git", requires = "nvim-lua/plenary.nvim" },
    { url = "https://codeberg.org/FelipeLema/cmp-async-path.git" },
  },

  ---@class opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    -- Add new sources
    opts.sources = opts.sources or {}
    opts.sources = vim.tbl_extend("force", opts.sources, {
      { name = "nvim_lua" },
      { name = "treesitter" },
      { name = "buffer" },
      { name = "bufname" },
      { name = "async_path" },
      { name = "git" },
      { name = "fish" },
      { name = "cmp_csv" },
      { name = "lazydev", group_index = 0 },
    })

    opts.window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    }

    -- Add cmdline sources
    cmp.setup.cmdline(":", {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
        { name = "cmdline_history" },
        { name = "cmdline" },
      }),
    })

    -- Set up supertab (https://github.com/ervandew/supertab)
    opts.preselect = cmp.PreselectMode.None
    opts.completion = {
      completeopt = "menu,menuone,noinsert,noselect",
    }

    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0
        and vim.api
            .nvim_buf_get_lines(0, line - 1, line, true)[1]
            :sub(col, col)
            :match("%s")
          == nil
    end

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
          -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
          -- they way you will only jump inside the snippet region
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),

      -- This makes sure "<CR>" with nothing selected just inserts a newline if you haven't selected anything.
      ["<CR>"] = cmp.mapping({
        i = function(fallback)
          if cmp.visible() and cmp.get_active_entry() then
            cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
          else
            fallback()
          end
        end,
        s = cmp.mapping.confirm({ select = true }),
        c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
      }),
    })
  end,
}
