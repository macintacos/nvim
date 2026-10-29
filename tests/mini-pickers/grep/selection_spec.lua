local selection = require("plugins.mini-pickers.grep.selection")

describe("grep_selection", function()
  describe("classify", function()
    it("replaces the query on a printable character", function()
      assert.equal("replace", selection.classify("a"))
      assert.equal("replace", selection.classify(" "))
      assert.equal("replace", selection.classify("é"))
    end)

    it("clears the query on backspace or delete-word", function()
      assert.equal("clear", selection.classify(vim.keycode("<BS>")))
      assert.equal("clear", selection.classify(vim.keycode("<C-w>")))
    end)

    it("keeps the text for editing on the arrow keys", function()
      assert.equal("edit", selection.classify(vim.keycode("<Left>")))
      assert.equal("edit", selection.classify(vim.keycode("<Right>")))
    end)

    it("just drops the selection on any other key", function()
      for _, key in ipairs({ "<CR>", "<Esc>", "<C-n>", "<M-x>", "<Tab>", "<Down>" }) do
        assert.equal("drop", selection.classify(vim.keycode(key)), key)
      end
    end)
  end)
end)
