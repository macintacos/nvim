-- github.com/chrisgrieser/nvim-recorder
-- A better macro recorder

---@module "lazy"
---@type LazySpec
return {
  -- simplify using macros
  "chrisgrieser/nvim-recorder",
  dependencies = "rcarriga/nvim-notify",
  opts = {
    mapping = {
      startStopRecording = "@",
    },
  },
}
