-- github.com/monaqa/dial.nvim
-- Increment and decrement numbers, dates, booleans, and more with C-a/C-x
vim.pack.add({ "https://github.com/monaqa/dial.nvim" }, { load = false })

-- Build the dial.map function name for the current context and invoke it.
-- Combines the direction (inc/dec), the "g" prefix variant (for g<C-a>),
-- and the mode (visual/normal) into a function name like "inc_normal" or
-- "dec_g_visual", then calls it with the filetype-specific augend group.
---@param increment boolean
---@param g? boolean
local function dial(increment, g)
  local mode = vim.fn.mode(true)
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
  local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[func](group)
end

-- Registers all augend groups and filetype mappings on first use.
-- Guarded so it only runs once even though multiple keymaps call it.
local loaded = false
local function ensure_loaded()
  if loaded then
    return
  end
  loaded = true
  vim.cmd.packadd("dial.nvim")

  local augend = require("dial.augend")

  local logical_alias = augend.constant.new({
    elements = { "&&", "||" },
    word = false,
    cyclic = true,
  })

  local ordinal_numbers = augend.constant.new({
    elements = {
      "first",
      "second",
      "third",
      "fourth",
      "fifth",
      "sixth",
      "seventh",
      "eighth",
      "ninth",
      "tenth",
    },
    word = false,
    cyclic = true,
  })

  local weekdays = augend.constant.new({
    elements = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
    word = true,
    cyclic = true,
  })

  local months = augend.constant.new({
    elements = {
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    },
    word = true,
    cyclic = true,
  })

  local capitalized_boolean = augend.constant.new({
    elements = { "True", "False" },
    word = true,
    cyclic = true,
  })

  local dials_by_ft = {
    css = "css",
    vue = "vue",
    javascript = "typescript",
    typescript = "typescript",
    typescriptreact = "typescript",
    javascriptreact = "typescript",
    json = "json",
    lua = "lua",
    markdown = "markdown",
    sass = "css",
    scss = "css",
    python = "python",
  }

  local groups = {
    default = {
      augend.integer.alias.decimal,
      augend.integer.alias.decimal_int,
      augend.integer.alias.hex,
      augend.date.alias["%Y/%m/%d"],
      ordinal_numbers,
      weekdays,
      months,
      capitalized_boolean,
      augend.constant.alias.bool,
      logical_alias,
    },
    vue = {
      augend.constant.new({ elements = { "let", "const" } }),
      augend.hexcolor.new({ case = "lower" }),
      augend.hexcolor.new({ case = "upper" }),
    },
    typescript = {
      augend.constant.new({ elements = { "let", "const" } }),
    },
    css = {
      augend.hexcolor.new({ case = "lower" }),
      augend.hexcolor.new({ case = "upper" }),
    },
    markdown = {
      augend.constant.new({
        elements = { "[ ]", "[x]" },
        word = false,
        cyclic = true,
      }),
      augend.misc.alias.markdown_header,
    },
    json = {
      augend.semver.alias.semver,
    },
    lua = {
      augend.constant.new({
        elements = { "and", "or" },
        word = true,
        cyclic = true,
      }),
    },
    python = {
      augend.constant.new({
        elements = { "and", "or" },
      }),
    },
  }

  for name, group in pairs(groups) do
    if name ~= "default" then
      vim.list_extend(group, groups.default)
    end
  end
  require("dial.config").augends:register_group(groups)
  vim.g.dials_by_ft = dials_by_ft
end

-- stylua: ignore start
vim.keymap.set({ "n", "v" }, "<C-a>", function() ensure_loaded(); return dial(true) end, { expr = true, desc = "Increment" })
vim.keymap.set({ "n", "v" }, "<C-x>", function() ensure_loaded(); return dial(false) end, { expr = true, desc = "Decrement" })
vim.keymap.set({ "n", "v" }, "g<C-a>", function() ensure_loaded(); return dial(true, true) end, { expr = true, desc = "Increment" })
vim.keymap.set({ "n", "v" }, "g<C-x>", function() ensure_loaded(); return dial(false, true) end, { expr = true, desc = "Decrement" })
-- stylua: ignore end
