local store = require("plugins.ftchooser.store")

describe("ftchooser.store", function()
  local file

  before_each(function()
    file = vim.fn.tempname()
  end)

  after_each(function()
    os.remove(file)
  end)

  it("returns an empty table when the store file is missing", function()
    assert.same({}, store.load(file))
  end)

  it("round-trips a remembered filetype through disk", function()
    store.set(file, "/proj/keymap.json", "jsonc")
    -- get() re-reads from disk, proving the value survives a fresh load
    -- (the "persists across restarts" guarantee).
    assert.equal("jsonc", store.get(file, "/proj/keymap.json"))
  end)

  it("keeps multiple entries and overwrites by key", function()
    store.set(file, "/a.json", "jsonc")
    store.set(file, "/b.yaml", "yaml")
    store.set(file, "/a.json", "json5")
    assert.equal("json5", store.get(file, "/a.json"))
    assert.equal("yaml", store.get(file, "/b.yaml"))
  end)

  it("returns nil for an unknown key", function()
    store.set(file, "/a.json", "jsonc")
    assert.is_nil(store.get(file, "/missing"))
  end)
end)
