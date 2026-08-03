vim.loader.enable()

require("config.options")
require("config.autocmds")
require("config.keymaps")
require("config.highlights")

-- Locate a plugin's install directory on disk. vim.pack stores plugins
-- under <data>/site/pack/<pack_name>/{opt,start}/<plugin>/, where
-- <pack_name> is typically "core". We glob across all pack names so
-- this stays resilient to future changes in the directory layout.
local function find_plugin_path(name)
  local base = vim.fn.stdpath("data") .. "/site/pack/"
  for _, subdir in ipairs({ "opt", "start" }) do
    local paths = vim.fn.glob(base .. "*/" .. subdir .. "/" .. name, false, true)
    if #paths > 0 then
      return paths[1]
    end
  end
end

-- Check for plugin updates asynchronously after startup — runs
-- git ls-remote for each plugin in a background thread pool
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    require("config.pack-updates").check()
  end,
})

-- Some plugins ship native code that must be compiled after cloning.
-- vim.pack fires PackChanged once per plugin on install or update —
-- we hook into it here to run the appropriate build step for each.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
      return
    end

    if name == "nvim-treesitter" then
      -- Ensure treesitter is loaded so :TSUpdate can find parsers
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    elseif name == "blink.cmp" then
      -- Build the Rust fuzzy-matching backend asynchronously.
      -- blink.cmp falls back to a pure-Lua implementation until
      -- the binary is available, so this won't block startup.
      -- blink.cmp loads the library from <plugin>/target/release/, but our
      -- global ~/.cargo/config.toml redirects every build to a shared cache
      -- dir, so pin CARGO_TARGET_DIR back in-tree (env wins over config.toml).
      local path = find_plugin_path("blink.cmp")
      if path then
        local opts = { cwd = path, env = { CARGO_TARGET_DIR = path .. "/target" } }
        vim.system({ "cargo", "build", "--release" }, opts, function(result)
          vim.schedule(function()
            if result.code ~= 0 then
              vim.notify("blink.cmp build failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
            end
          end)
        end)
      end
    elseif name == "fff.nvim" then
      -- Download the prebuilt binary (or compile from source)
      if not ev.data.active then
        vim.cmd.packadd("fff.nvim")
      end
      require("fff.download").download_or_build_binary()
    end
  end,
})
