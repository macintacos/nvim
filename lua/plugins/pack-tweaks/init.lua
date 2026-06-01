local M = {}

---@class pack-tweaks.Config

---Register the pack-tweaks behaviors. Currently this wires a single
---`FileType nvim-pack` autocmd that attaches per-feature keymaps to each
---vim.pack confirmation buffer; future tweaks add a module + one `attach` call.
---@param _opts pack-tweaks.Config|nil
function M.setup(_opts)
  -- Attach pack-tweaks keymaps to vim.pack's update confirmation buffer.
  -- vim.pack sets `filetype=nvim-pack` on that buffer (nvim-pack://confirm#N);
  -- this is the single hook point through which each feature binds its
  -- buffer-local maps. vim.schedule defers the attach so it lands after the
  -- runtime ftplugin (which sets [[ and ]]) finishes loading.
  -- Fires: when a vim.pack confirmation buffer's filetype is detected.
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("PackTweaks", { clear = true }),
    pattern = "nvim-pack",
    desc = "Attach pack-tweaks keymaps to the vim.pack update buffer",
    callback = function(ev)
      vim.schedule(function()
        require("plugins.pack-tweaks.open_commit").attach(ev.buf)
      end)
    end,
  })
end

return M
