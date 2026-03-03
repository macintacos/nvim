-- github.com/dmtrKovalenko/fff.nvim
-- Fast Fuzzy File Finder

---@module "lazy"
---@type LazySpec
return {
  "dmtrKovalenko/fff.nvim",
  build = function()
    -- this will download prebuild binary or try to use existing rustup toolchain to build from source
    -- (if you are using lazy you can use gb for rebuilding a plugin if needed)
    require("fff.download").download_or_build_binary()
  end,
  opts = {
    debug = {
      enabled = false,
      show_scores = false,
    },
    layout = {
      prompt_position = "top",
    },
    preview = {
      show_file_info = true,
    },
  },
  -- No need to lazy-load with lazy.nvim, this plugin initializes itself lazily.
  lazy = false,
}
