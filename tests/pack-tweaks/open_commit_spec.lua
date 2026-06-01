local oc = require("plugins.pack-tweaks.open_commit")

describe("pack-tweaks open_commit", function()
  describe("_parse_target", function()
    it("extracts an added commit short SHA", function()
      local target, kind = oc._parse_target("> a1b2c3d │ feat: add X")
      assert.equal("a1b2c3d", target)
      assert.equal("commit", kind)
    end)

    it("extracts a reverted commit short SHA", function()
      local target, kind = oc._parse_target("< d4e5f6a │ revert Y")
      assert.equal("d4e5f6a", target)
      assert.equal("commit", kind)
    end)

    it("extracts a commit SHA from a 'Revision after' line", function()
      local target, kind = oc._parse_target("Revision after:  1c2d3e4f5a6b (v1.2.0)")
      assert.equal("1c2d3e4f5a6b", target)
      assert.equal("commit", kind)
    end)

    it("extracts a commit SHA from a 'Revision before' line", function()
      local target, kind = oc._parse_target("Revision before: 9f8e7d6c5b4a")
      assert.equal("9f8e7d6c5b4a", target)
      assert.equal("commit", kind)
    end)

    it("extracts a commit SHA from a same-revision line", function()
      local target, kind = oc._parse_target("Revision: 1122334455aa (v2.0.0)")
      assert.equal("1122334455aa", target)
      assert.equal("commit", kind)
    end)

    it("extracts a tag from an available-version line", function()
      local target, kind = oc._parse_target("• v1.2.0")
      assert.equal("v1.2.0", target)
      assert.equal("tag", kind)
    end)

    it("returns nil for a Source line", function()
      assert.is_nil(oc._parse_target("Source:   https://github.com/foo/bar"))
    end)

    it("returns nil for a plugin header line", function()
      assert.is_nil(oc._parse_target("## my-plugin"))
    end)

    it("returns nil for a blank line", function()
      assert.is_nil(oc._parse_target(""))
    end)
  end)

  describe("_find_source", function()
    local lines = {
      "## my-plugin",
      "Path:            /x/y/my-plugin",
      "Source:          https://github.com/foo/bar",
      "Revision before: aaaaaaa",
      "Revision after:  bbbbbbb",
      "",
      "Pending updates:",
      "> a1b2c3d │ feat: add X",
    }

    it("walks backward to the section's Source line", function()
      assert.equal("https://github.com/foo/bar", oc._find_source(lines, 8))
    end)

    it("returns the Source on the Source line itself", function()
      assert.equal("https://github.com/foo/bar", oc._find_source(lines, 3))
    end)

    it("returns nil when no Source precedes the line", function()
      assert.is_nil(oc._find_source({ "## orphan", "> a1b2c3d │ x" }, 2))
    end)
  end)

  describe("_build_url", function()
    it("builds a commit URL", function()
      assert.equal(
        "https://github.com/foo/bar/commit/a1b2c3d",
        oc._build_url("https://github.com/foo/bar", "a1b2c3d", "commit")
      )
    end)

    it("builds a tag release URL", function()
      assert.equal(
        "https://github.com/foo/bar/releases/tag/v1.2.0",
        oc._build_url("https://github.com/foo/bar", "v1.2.0", "tag")
      )
    end)

    it("strips a trailing .git from the source", function()
      assert.equal(
        "https://github.com/foo/bar/commit/a1b2c3d",
        oc._build_url("https://github.com/foo/bar.git", "a1b2c3d", "commit")
      )
    end)
  end)
end)

describe("pack-tweaks open_commit (integration)", function()
  local saved_open, saved_notify
  local opened, notified

  before_each(function()
    saved_open, saved_notify = vim.ui.open, vim.notify
    opened, notified = nil, nil
    vim.ui.open = function(url)
      opened = url
    end
    vim.notify = function(msg)
      notified = msg
    end
  end)

  after_each(function()
    vim.ui.open, vim.notify = saved_open, saved_notify
  end)

  -- Attach the keymap to a scratch buffer, position the cursor, and fire the
  -- registered <CR> callback end-to-end (exercising attach + open_at_cursor).
  local function attach_and_press(lines, row)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_current_buf(buf)
    oc.attach(buf)
    local cb
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
      if m.desc == "Open commit/tag in remote" then
        cb = m.callback
      end
    end
    assert.is_function(cb)
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    cb()
  end

  local update_section = {
    "# Update ────",
    "## my-plugin",
    "Path:            /x/y/my-plugin",
    "Source:          https://github.com/foo/bar",
    "Revision before: aaaaaaa",
    "Revision after:  bbbbbbb (v1.2.0)",
    "",
    "Pending updates:",
    "> a1b2c3d │ feat: add X",
    "< d4e5f6a │ revert Y",
  }

  it("opens the commit on the cursor line", function()
    attach_and_press(update_section, 9)
    assert.equal("https://github.com/foo/bar/commit/a1b2c3d", opened)
  end)

  it("uses the line under the cursor, not an adjacent one", function()
    attach_and_press(update_section, 10)
    assert.equal("https://github.com/foo/bar/commit/d4e5f6a", opened)
  end)

  it("opens the tag release page on an available-version line", function()
    attach_and_press({
      "# Same ────",
      "## other",
      "Path:     /a/b",
      "Source:   https://github.com/baz/qux",
      "Revision: 99aabb (v2.0.0)",
      "",
      "Available newer versions:",
      "• v3.0.0",
    }, 8)
    assert.equal("https://github.com/baz/qux/releases/tag/v3.0.0", opened)
  end)

  it("does nothing on a non-target line", function()
    attach_and_press(update_section, 2)
    assert.is_nil(opened)
    assert.is_nil(notified)
  end)

  it("warns and does not open when no Source precedes the line", function()
    attach_and_press({ "## orphan", "> a1b2c3d │ x" }, 2)
    assert.is_nil(opened)
    assert.is_not_nil(notified)
  end)
end)
