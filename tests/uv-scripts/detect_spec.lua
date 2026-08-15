local detect = require("plugins.uv-scripts.detect")

---Create a scratch buffer holding the given lines.
---@param lines string[]
---@return integer bufnr
local function buf_with(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return bufnr
end

describe("uv-scripts.detect", function()
  local bufs

  before_each(function()
    bufs = {}
  end)

  after_each(function()
    for _, b in ipairs(bufs) do
      if vim.api.nvim_buf_is_valid(b) then
        vim.api.nvim_buf_delete(b, { force = true })
      end
    end
  end)

  ---@param lines string[]
  ---@return integer
  local function scratch(lines)
    local b = buf_with(lines)
    table.insert(bufs, b)
    return b
  end

  describe("has_inline_metadata", function()
    it("detects a PEP 723 script block", function()
      local b = scratch({ "# /// script", '# dependencies = ["httpx"]', "# ///", "import httpx" })
      assert.is_true(detect.has_inline_metadata(b))
    end)

    it("detects a block that follows a shebang", function()
      local b = scratch({ "#!/usr/bin/env -S uv run --script", "# /// script", "# ///" })
      assert.is_true(detect.has_inline_metadata(b))
    end)

    it("ignores a non-script block type", function()
      -- PEP 723 reserves other block types; only `script` carries dependencies.
      local b = scratch({ "# /// pyproject", "# ///", "import os" })
      assert.is_false(detect.has_inline_metadata(b))
    end)

    it("ignores a plain python file", function()
      local b = scratch({ "import os", "", "print(os.getcwd())" })
      assert.is_false(detect.has_inline_metadata(b))
    end)

    it("ignores the marker inside a string literal", function()
      -- The opening line must be a comment at the start of a line.
      local b = scratch({ 'doc = "# /// script"', "print(doc)" })
      assert.is_false(detect.has_inline_metadata(b))
    end)
  end)

  describe("has_uv_shebang", function()
    it("detects the -S form uv documents", function()
      local b = scratch({ "#!/usr/bin/env -S uv run --script", "import httpx" })
      assert.is_true(detect.has_uv_shebang(b))
    end)

    it("detects a bare uv run shebang", function()
      local b = scratch({ "#!/usr/bin/env -S uv run", "import httpx" })
      assert.is_true(detect.has_uv_shebang(b))
    end)

    it("detects an absolute path to uv", function()
      local b = scratch({ "#!/usr/local/bin/uv run --script", "import httpx" })
      assert.is_true(detect.has_uv_shebang(b))
    end)

    it("ignores a plain python shebang", function()
      local b = scratch({ "#!/usr/bin/env python3", "import os" })
      assert.is_false(detect.has_uv_shebang(b))
    end)

    it("ignores a shell shebang", function()
      local b = scratch({ "#!/bin/sh", "echo uv run" })
      assert.is_false(detect.has_uv_shebang(b))
    end)

    it("ignores uv run mentioned below the first line", function()
      local b = scratch({ "#!/bin/sh", "exec uv run --script foo.py" })
      assert.is_false(detect.has_uv_shebang(b))
    end)
  end)

  describe("filetype", function()
    it("claims a uv shebang script as python", function()
      local b = scratch({ "#!/usr/bin/env -S uv run --script", "import httpx" })
      assert.equal("python", detect.filetype("/home/u/bin/deploy", b))
    end)

    it("claims an extensionless script carrying only a metadata block", function()
      local b = scratch({ "# /// script", '# dependencies = ["httpx"]', "# ///" })
      assert.equal("python", detect.filetype("/home/u/bin/deploy", b))
    end)

    it("declines a shell script so neovim's own detection still runs", function()
      local b = scratch({ "#!/bin/sh", "echo hello" })
      assert.is_nil(detect.filetype("/home/u/bin/deploy", b))
    end)

    it("declines an empty buffer", function()
      local b = scratch({})
      assert.is_nil(detect.filetype("/home/u/bin/deploy", b))
    end)
  end)
end)
