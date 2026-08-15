local uv_scripts = require("plugins.uv-scripts")

---@param lines string[]
---@return integer bufnr
local function scratch(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return bufnr
end

describe("uv-scripts.setup", function()
  before_each(function()
    uv_scripts.setup()
  end)

  describe("filetype registration", function()
    it("resolves an extensionless uv shebang script to python", function()
      local b = scratch({ "#!/usr/bin/env -S uv run --script", "import httpx" })
      assert.equal("python", vim.filetype.match({ buf = b, filename = "/home/u/bin/deploy" }))
    end)

    it("leaves a shell script to neovim's own detection", function()
      local b = scratch({ "#!/bin/sh", "echo hello" })
      assert.equal("sh", vim.filetype.match({ buf = b, filename = "/home/u/bin/deploy" }))
    end)

    it("does not override detection driven by a file extension", function()
      local b = scratch({ "#!/usr/bin/env -S uv run --script", "print(1)" })
      assert.equal("lua", vim.filetype.match({ buf = b, filename = "/home/u/init.lua" }))
    end)

    it("survives another plugin registering its own catch-all pattern", function()
      -- snacks.nvim's bigfile registers `pattern[".*"]`. vim.filetype.add keys
      -- patterns by string, so sharing that key means whichever plugin registers
      -- last silently replaces the other.
      vim.filetype.add({
        pattern = {
          [".*"] = function()
            return nil
          end,
        },
      })
      local b = scratch({ "#!/usr/bin/env -S uv run --script", "import httpx" })
      assert.equal("python", vim.filetype.match({ buf = b, filename = "/home/u/bin/deploy" }))
    end)
  end)

  describe("client_config", function()
    it("points ty at the interpreter uv resolved", function()
      local cfg = uv_scripts.client_config("/home/u/bin/deploy", "/cache/env/bin/python3")
      assert.equal("/cache/env/bin/python3", cfg.settings.ty.configuration.environment.python)
    end)

    it("roots the client at the script's directory", function()
      local cfg = uv_scripts.client_config("/home/u/bin/deploy", "/cache/env/bin/python3")
      assert.equal("/home/u/bin", cfg.root_dir)
    end)

    it("names clients per script so two in one directory stay separate", function()
      local a = uv_scripts.client_config("/home/u/bin/deploy", "/cache/a/bin/python3")
      local b = uv_scripts.client_config("/home/u/bin/report", "/cache/b/bin/python3")
      assert.are_not.equal(a.name, b.name)
    end)

    it("runs the ty language server", function()
      local cfg = uv_scripts.client_config("/home/u/bin/deploy", "/cache/env/bin/python3")
      assert.same({ "ty", "server" }, cfg.cmd)
    end)
  end)
end)
