local deps = require("support.deps")
for _, plugin in ipairs({ "mini.pick", "mini.icons", "tabby.nvim" }) do
  vim.opt.rtp:prepend(deps.path(plugin))
end
require("mini.pick").setup()
require("mini.icons").setup()

local number_box = require("helpers.tabs").number_box
local tabs = require("plugins.mini-pickers.tabs")

---Open the tab picker, run `step` once it is up, then wait for any tab switch
---its choice schedules.
---
---`MiniPick.start` blocks until the picker stops, so `step` runs from a timer
---the picker's key loop fires while it waits for input.
---@param step fun()
local function drive(step)
  vim.defer_fn(step, 50)
  tabs.pick()
  vim.wait(50)
end

---The highlight groups `row` colors, in order.
---@param row { hls: { [3]: string }[] }
---@return string[]
local function groups(row)
  return vim.tbl_map(function(hl)
    return hl[3]
  end, row.hls)
end

describe("mini-pickers.tabs", function()
  before_each(function()
    vim.cmd("edit a.lua | tabnew b.lua")
  end)

  after_each(function()
    vim.cmd("silent! tabonly! | silent! %bwipeout!")
  end)

  describe("_rows", function()
    it("lists every tab in tabline order, then a row that opens a new one", function()
      local list = vim.api.nvim_list_tabpages()
      local rows = tabs._rows(list, assert(list[2]))
      local icon = MiniIcons.get("file", "a.lua")
      assert.equal(number_box(1) .. " " .. icon .. " a.lua", assert(rows[1]).text)
      assert.equal(list[2], assert(rows[2]).tab)
      assert.matches("New Tab$", assert(rows[3]).text)
      assert.is_nil(assert(rows[3]).tab)
    end)

    it("marks the current tab's number", function()
      local list = vim.api.nvim_list_tabpages()
      local rows = tabs._rows(list, assert(list[2]))
      assert.equal("Comment", groups(assert(rows[1]))[1])
      assert.equal("MiniPickTabCurrent", groups(assert(rows[2]))[1])
    end)

    it("italicizes the name of a tab with unsaved changes", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "changed" })
      local list = vim.api.nvim_list_tabpages()
      local rows = tabs._rows(list, assert(list[2]))
      assert.is_false(vim.tbl_contains(groups(assert(rows[1])), "MiniPickTabUnsaved"))
      assert.equal("MiniPickTabUnsaved", groups(assert(rows[2]))[3])
    end)

    it("gives a scratch file's tab the tabline's scratch icon and color", function()
      vim.cmd("tabnew /project/.tmp/scratch/notes.md")
      local list = vim.api.nvim_list_tabpages()
      local look = assert(require("helpers.tabs").special(vim.api.nvim_get_current_buf()))
      local scratch = assert(tabs._rows(list, assert(list[1]))[3])
      assert.matches(look.icon, scratch.text, 1, true)
      assert.same({ "Comment", "MiniPickTabScratch", "MiniPickTabScratch" }, groups(scratch))
    end)
  end)

  describe("pick", function()
    it("opens with the current tab selected", function()
      local current
      drive(function()
        current = assert(MiniPick.get_picker_matches()).current.tab
        MiniPick.stop()
      end)
      assert.equal(vim.api.nvim_get_current_tabpage(), current)
    end)

    it("switches to the chosen tab", function()
      local first = vim.api.nvim_list_tabpages()[1]
      drive(function()
        vim.api.nvim_input("<C-p><CR>")
      end)
      assert.equal(first, vim.api.nvim_get_current_tabpage())
    end)

    it("opens a new tab from the last row", function()
      drive(function()
        vim.api.nvim_input("<C-n><CR>")
      end)
      assert.equal(3, #vim.api.nvim_list_tabpages())
      assert.equal(3, vim.fn.tabpagenr())
    end)
  end)
end)
