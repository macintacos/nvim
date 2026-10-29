local M = {}

---Start a picker and run `steps` against it in turn, then stop it.
---
---`MiniPick.start` blocks until the picker stops, so each step is a timer the
---picker's key loop runs while it waits for input — spaced out so the previous
---step's keys have been handled by the time the next one looks.
---@param start fun() Starts the picker, e.g. `function() MiniPick.start(opts) end`.
---@param steps fun()[]
function M.drive(start, steps)
  local i = 0
  local function step()
    i = i + 1
    if steps[i] then
      steps[i]()
      vim.defer_fn(step, 50)
    elseif MiniPick.is_picker_active() then
      MiniPick.stop()
    end
  end
  vim.defer_fn(step, 50)
  start()
end

return M
