local whichkey = require("plugins.mini-pickers.whichkey")

---A which-key tree node, reduced to the fields `_rows` reads.
---@param keys string
---@param desc string?
---@param parent table?
---@param rhs string?
---@return table
local function node(keys, desc, parent, rhs)
  return { keys = keys, desc = desc, parent = parent, keymap = rhs and { rhs = rhs } or nil }
end

describe("mini-pickers.whichkey", function()
  describe("_rows", function()
    it("spells the leader out and pads every label to the same column", function()
      local rows = whichkey._rows({ node("<Space>gs", "Open Lazygit"), node("<Space>q", "Quit") })
      assert.equal("<leader>gs", rows[1].lhs)
      assert.equal("<leader>gs  Open Lazygit", rows[1].text)
      assert.equal("<leader>q   Quit", rows[2].text)
    end)

    it("keeps the raw keys for feedkeys", function()
      local rows = whichkey._rows({ node("<Space>gs", "Open Lazygit") })
      assert.equal("<Space>gs", rows[1].keys)
    end)

    it("folds the group trail into the matched text", function()
      local root = { desc = "git", parent = { parent = nil } }
      local rows = whichkey._rows({ node("<Space>gs", "Open Lazygit", root) })
      assert.equal("<leader>gs  git » Open Lazygit", rows[1].text)
    end)

    it("falls back to the rhs when a mapping carries no description", function()
      local rows = whichkey._rows({ node("gx", nil, nil, "<Plug>(openbrowser-smart-search)") })
      assert.equal("gx  <Plug>(openbrowser-smart-search)", rows[1].text)
    end)

    it("drops a mapping with neither a description nor a string rhs", function()
      assert.same({}, whichkey._rows({ node("<Space>zz") }))
    end)
  end)
end)
