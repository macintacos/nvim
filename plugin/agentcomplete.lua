-- github.com/macintacos/agentcomplete.nvim
-- Agent completions when editing prompts in a buffer
vim.pack.add({ "https://github.com/macintacos/agentcomplete.nvim" })

-- setup() gets called in ./blink.lua

-- Turn off the rumdl markdown LINTER (its lint diagnostics) in agent prompt
-- buffers: agentcomplete's own slash/@ noise shouldn't get flagged. Fires when
-- rumdl attaches to a detected agentcomplete session. We disable the buffer's
-- diagnostics rather than detach the client, because conform formats these
-- buffers THROUGH the rumdl LSP: with `lsp_format = "fallback"`, when the external
-- `rumdl` binary isn't on Neovim's PATH conform uses the server to format, so
-- detaching would kill formatting too. rumdl is the only diagnostic source on a
-- claude-prompt buffer, so disabling buffer diagnostics only silences rumdl.
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "rumdl" and require("agentcomplete.detect").detect(args.buf) then
      vim.diagnostic.enable(false, { bufnr = args.buf })
    end
  end,
})
