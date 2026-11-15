---A centered picker over the project's mise tasks, `mise tasks info` beneath it;
---choosing one runs it in a floating Rex pane.

local M = {}

local NS = vim.api.nvim_create_namespace("mise-tasks")

-- Keeps the rows a cell off the float's border.
local PAD = " "
local GAP = "  "

-- Room for the INFO float, which shares the list's width: its title, keybar, and info lines.
local MIN_WIDTH = 50
-- Keeps one long name from widening the whole block.
local NAME_MAX = 30
local PREVIEW_HEIGHT = 8

-- A float's border takes a row above and below, a cell either side.
local BORDER = 2

-- The Rex pane as { x, y, width, height }, fractions of the Rex window: its middle 80%.
local PANE_BOUNDS = { 0.1, 0.1, 0.8, 0.8 }

---@type [string, string][]
local KEYBAR = {
  { " ↵ ", "MiniPickBorderText" },
  { "run  ", "MiniPickKeybarLabel" },
  { "⇧↵ ", "MiniPickBorderText" },
  { "with arguments ", "MiniPickKeybarLabel" },
}

---@class mise-tasks.Task
---@field name string
---@field description string
---@field text string What mini.pick draws and matches: the name, which show() places the description after.

---@class mise-tasks.Placement : vim.api.keyset.win_config
---@field row integer
---@field col integer
---@field width integer
---@field height integer

---@class mise-tasks.Layout
---@field list mise-tasks.Placement
---@field preview mise-tasks.Placement

---The program the Rex pane runs. Typed arguments go through `sh`, so they quote
---as they would at a prompt; the task name stays out of the script.
---@param name string
---@param args string?
---@return string[]
function M._command(name, args)
  if not args or vim.trim(args) == "" then
    return { "mise", "run", name }
  end
  return { "sh", "-c", 'exec mise run "$1" ' .. vim.trim(args), "mise-tasks", name }
end

---The column descriptions start at: the widest name, capped at NAME_MAX.
---@param tasks mise-tasks.Task[]
---@return integer
local function name_column(tasks)
  local column = 0
  for _, task in ipairs(tasks) do
    column = math.max(column, math.min(vim.api.nvim_strwidth(task.name), NAME_MAX))
  end
  return column
end

---The list and preview floats, stacked and centered together in the editor.
---@param tasks mise-tasks.Task[]
---@param columns integer
---@param lines integer
---@return mise-tasks.Layout
function M._layout(tasks, columns, lines)
  local column = name_column(tasks)
  local natural_width = MIN_WIDTH
  for _, task in ipairs(tasks) do
    natural_width = math.max(natural_width, 2 * #PAD + column + #GAP + vim.api.nvim_strwidth(task.description))
  end
  local width = math.max(math.min(natural_width, math.floor(0.8 * columns), columns - BORDER), 1)

  -- The list gets what 60% of the editor leaves after the preview and both floats' borders.
  local preview_height = math.max(math.min(PREVIEW_HEIGHT, math.floor((lines - 2 * BORDER) / 3)), 1)
  local list_height = math.max(math.min(#tasks, math.floor(0.6 * lines) - preview_height - 2 * BORDER), 1)
  local top = math.max(math.floor((lines - (list_height + preview_height + 2 * BORDER)) / 2), 0)
  local col = math.floor((columns - width - BORDER) / 2)

  return {
    list = { relative = "editor", anchor = "NW", row = top, col = col, width = width, height = list_height },
    preview = {
      relative = "editor",
      anchor = "NW",
      row = top + list_height + BORDER,
      col = col,
      width = width,
      height = preview_height,
    },
  }
end

---Run mise in Neovim's cwd.
---@param args string[]
---@return string? stdout Nil when mise fails.
---@return string? err What mise said when it failed.
local function mise(args)
  local result =
    vim.system(vim.list_extend({ "mise" }, args), { cwd = vim.fn.getcwd(), text = true, timeout = 5000 }):wait()
  if result.code == 124 then
    return nil, "mise timed out"
  elseif result.code ~= 0 then
    return nil, vim.trim(result.stderr ~= "" and result.stderr or result.stdout or "")
  end
  return result.stdout
end

---The tasks mise lists here.
---@return mise-tasks.Task[]? tasks
---@return string? err
local function list()
  local out, err = mise({ "tasks", "ls", "--json" })
  if not out then
    return nil, err
  end
  local ok, decoded = pcall(vim.json.decode, out)
  if not ok or type(decoded) ~= "table" then
    return nil, "couldn't read `mise tasks ls --json`"
  end
  local tasks = {}
  for _, task in ipairs(decoded) do
    tasks[#tasks + 1] = { name = task.name, description = task.description or "", text = task.name }
  end
  return tasks
end

---Open `command` in a floating Rex pane in `cwd`.
---@param label string
---@param command string[]
---@param cwd string
local function open_rex_pane(label, command, cwd)
  local payload = vim.json.encode({
    bounds = PANE_BOUNDS,
    focus = true,
    layout = {
      block = {
        flavor = "com.superlogical.terminal.shell",
        label = label,
        -- Stays open once the task ends, so its output can be read.
        options = { command = command, cwd = cwd, exit = { on_completion = false } },
      },
    },
  })
  vim.system(
    { vim.env.REX_BIN_DIR .. "/rex", "api", "call", "-s", vim.env.REX_SESSION, "session.new_layer", "-" },
    { stdin = payload, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify("mise-tasks: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
      end
    end)
  )
end

---@param name string
---@param args string?
local function run(name, args)
  local label = vim.trim("mise run " .. name .. " " .. (args or ""))
  open_rex_pane(label, M._command(name, args), vim.fn.getcwd())
end

---Ask for the task's arguments in a float with the picker's width and column, then
---run it with them. Calls MiniInput directly because vim.ui.input can't place the float.
---@param name string
---@param picker mise-tasks.Placement
local function run_with_args(name, picker)
  local args = MiniInput.get({
    prompt = "mise run " .. name,
    scope = "editor",
    handlers = {
      view = MiniInput.gen_view.floatwin({
        style = "MM",
        adjust_config = function(_, config)
          config.width, config.col = picker.width, picker.col
          return config
        end,
      }),
    },
  })
  if args then
    run(name, args)
  end
end

---`source.show`: the names as mini.pick draws them, each description dimmed in
---a column after them.
---@param tasks mise-tasks.Task[]
---@return fun(buf: integer, shown: mise-tasks.Task[], query: string[])
local function show(tasks)
  local column = name_column(tasks)
  return function(buf, shown, query)
    MiniPick.default_show(buf, shown, query)
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
    local current = (MiniPick.get_picker_matches() or {}).current
    for i, task in ipairs(shown) do
      local gap = (" "):rep(math.max(column - vim.api.nvim_strwidth(task.name), 0)) .. GAP
      -- mini.pick's current-row band starts at the row's first character, so the
      -- leading pad carries the band itself.
      local pad_hl = task == current and { "MiniPickMatchCurrent", "MiniPickNormal" } or "MiniPickNormal"
      vim.api.nvim_buf_set_extmark(buf, NS, i - 1, 0, {
        virt_text = { { PAD, pad_hl } },
        virt_text_pos = "inline",
        priority = 199,
      })
      vim.api.nvim_buf_set_extmark(buf, NS, i - 1, #task.name, {
        virt_text = { { gap .. task.description, "Comment" } },
        virt_text_pos = "inline",
        hl_mode = "combine",
        priority = 199,
      })
    end
  end
end

---`mise tasks info` for each task, cached for the picker's life.
---@return fun(buf: integer, task: mise-tasks.Task)
local function info()
  ---@type table<string, string[]>
  local cache = {}
  return function(buf, task)
    if not cache[task.name] then
      local out, err = mise({ "tasks", "info", task.name })
      cache[task.name] = vim.tbl_map(function(line)
        return PAD .. line
      end, vim.split(vim.trim(out or err or ""), "\n"))
    end
    local lines = cache[task.name]
    vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- Dim each `Field:` label so the values read first.
    for i, line in ipairs(lines) do
      local label = line:match("^" .. PAD .. "[%w ]+:")
      if label then
        vim.api.nvim_buf_set_extmark(buf, NS, i - 1, #PAD, { end_col = #label, hl_group = "Comment" })
      end
    end
  end
end

---Keep a preview float under the list on the current task until the picker stops.
---@param config vim.api.keyset.win_config
---@param preview fun(buf: integer, task: mise-tasks.Task)
local function attach(config, preview)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(
    buf,
    false,
    vim.tbl_extend("force", config, {
      style = "minimal",
      focusable = false,
      zindex = vim.api.nvim_win_get_config(assert(MiniPick.get_picker_state()).windows.main).zindex,
      title = { { " INFO ", "MiniPickBorderText" } },
      footer = KEYBAR,
      footer_pos = "right",
      noautocmd = true,
    })
  )
  local group = vim.api.nvim_create_augroup("MiseTasks.Preview", { clear = true })
  local shown_task

  local function render()
    local matches = MiniPick.is_picker_active() and MiniPick.get_picker_matches()
    local task = matches and matches.current
    if task == shown_task or not vim.api.nvim_win_is_valid(win) then
      return
    end
    shown_task = task
    if task then
      preview(buf, task)
    else
      vim.api.nvim_buf_clear_namespace(buf, NS, 0, -1)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    end
    -- mini.pick waits in getcharstr, which doesn't repaint on its own.
    vim.cmd.redraw()
  end

  -- mini.pick emits no event when the current row moves, but every move is a
  -- key it reads. Scheduled so the picker has handled the key first.
  vim.on_key(function()
    vim.schedule(render)
  end, NS)

  -- A query change resets the current row without a move key.
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "MiniPickMatch", callback = render })

  -- Close the preview with the picker it belongs to.
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "MiniPickStop",
    once = true,
    callback = function()
      vim.on_key(nil, NS)
      vim.api.nvim_del_augroup_by_id(group)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  render()
end

---Pick one of the project's mise tasks and run it in a floating Rex pane.
function M.pick()
  if vim.fn.executable("mise") ~= 1 then
    vim.notify("mise-tasks: mise isn't on PATH", vim.log.levels.ERROR)
    return
  end
  if not (vim.env.REX_BIN_DIR and vim.env.REX_SESSION) then
    vim.notify("mise-tasks: run Neovim inside Rex to run tasks in a pane", vim.log.levels.WARN)
    return
  end
  local tasks, err = list()
  if not tasks then
    vim.notify("mise-tasks: " .. err, vim.log.levels.ERROR)
    return
  elseif #tasks == 0 then
    vim.notify("mise-tasks: no tasks in " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":~"), vim.log.levels.INFO)
    return
  end

  local layout = M._layout(tasks, vim.o.columns, vim.o.lines)
  local rows = show(tasks)
  -- Opens the INFO float once the picker is up, the first moment its window
  -- exists. Fires on the next MiniPickStart, which may not be this picker:
  -- MiniPick.start returns early from the command-line window, leaving the hook armed.
  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("MiseTasks.Start", { clear = true }),
    pattern = "MiniPickStart",
    once = true,
    callback = function()
      local started = MiniPick.get_picker_opts()
      if started and started.source.show == rows then
        attach(layout.preview, info())
      end
    end,
  })

  ---@param task mise-tasks.Task?
  ---@param then_run fun(name: string)
  local function after_close(task, then_run)
    if task then
      -- After the picker closes, so the pane and prompt take focus from Neovim.
      vim.schedule(function()
        then_run(task.name)
      end)
    end
  end

  MiniPick.start({
    source = {
      name = "Mise tasks",
      items = tasks,
      show = rows,
      choose = function(task)
        after_close(task, run)
      end,
    },
    mappings = {
      run_with_args = {
        char = "<S-CR>",
        func = function()
          after_close((MiniPick.get_picker_matches() or {}).current, function(name)
            run_with_args(name, layout.list)
          end)
          return true
        end,
      },
    },
    window = { config = layout.list },
  })
end

return M
