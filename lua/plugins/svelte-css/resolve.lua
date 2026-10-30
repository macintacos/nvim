---Applies Svelte's style scoping to a project's parsed classes: a component's
---`<style>` reaches only its own markup, while stylesheets and `:global(…)` rules
---reach every component.

local M = {}

---@alias svelte_css.Project table<string, svelte_css.Classes> Keyed by absolute path

---@class svelte_css.Target
---@field path string
---@field name string
---@field selector? svelte_css.Definition The selector under the cursor; nil on a use in markup
---@field component? boolean On a component's tag, where its own file's scoped rules do not reach

---@class svelte_css.Hit
---@field path string
---@field site svelte_css.Site

---@class svelte_css.RuleHit : svelte_css.Hit
---@field site svelte_css.Definition

---@param path string
---@return boolean
local function is_stylesheet(path)
  return vim.endswith(path, ".css")
end

---@param site svelte_css.Site
---@param row integer
---@param col integer
---@return boolean
local function covers(site, row, col)
  return site.range[1] == row and site.range[2] <= col and col < site.range[4]
end

---The target's own file first, then the rest in path order.
---@param project svelte_css.Project
---@param first string
---@return string[]
local function paths_from(project, first)
  local rest = vim.tbl_filter(function(path)
    return path ~= first
  end, vim.tbl_keys(project))
  table.sort(rest)
  table.insert(rest, 1, first)
  return rest
end

---The class under a cursor in `path`, or nil when the cursor is on none.
---@param project svelte_css.Project
---@param path string
---@param row integer 0-based
---@param col integer 0-based byte column
---@return svelte_css.Target?
function M.at(project, path, row, col)
  local classes = project[path]
  if not classes then
    return nil
  end
  for _, def in ipairs(classes.definitions) do
    if covers(def, row, col) then
      return { path = path, name = def.name, selector = def }
    end
  end
  for _, use in ipairs(classes.uses) do
    if covers(use, row, col) then
      return { path = path, name = use.name, component = use.component }
    end
  end
  return nil
end

---The rules within reach of the target that name its class in a selector `counts`, each
---once.
---@param project svelte_css.Project
---@param target svelte_css.Target
---@param counts fun(def: svelte_css.Definition): boolean
---@return svelte_css.RuleHit[]
local function reaching(project, target, counts)
  local hits, seen = {}, {}
  for _, path in ipairs(paths_from(project, target.path)) do
    for _, def in ipairs(project[path].definitions) do
      local key = path .. ":" .. def.rule_start
      local reaches = (path == target.path and not target.component) or is_stylesheet(path) or def.global
      if def.name == target.name and counts(def) and reaches and not seen[key] then
        seen[key] = true
        table.insert(hits, { path = path, site = def })
      end
    end
  end
  return hits
end

---Every rule within reach of the target that names its class anywhere in a selector:
---its own file's, every stylesheet's, and every `:global(…)` one. On a component's tag,
---its own file's scoped rules do not count. Each rule appears once.
---@param project svelte_css.Project
---@param target svelte_css.Target
---@return svelte_css.RuleHit[]
function M.rules(project, target)
  return reaching(project, target, function()
    return true
  end)
end

---The rules among `rules` that style an element carrying the target's class: those
---with a selector that has the class in its rightmost compound.
---@param project svelte_css.Project
---@param target svelte_css.Target
---@return svelte_css.RuleHit[]
function M.definitions(project, target)
  return reaching(project, target, function(def)
    return def.subject
  end)
end

---@param hit svelte_css.RuleHit
---@return boolean
local function styles_everywhere(hit)
  return is_stylesheet(hit.path) or hit.site.global
end

---The markup uses of the target's class within the reach of its `rules`: the target's
---own component, except its components' tags, or every component when a stylesheet
---or `:global(…)` rule names it.
---None for a class no rule names, which belongs to another server, such as Tailwind's.
---@param project svelte_css.Project
---@param target svelte_css.Target
---@return svelte_css.Hit[]
function M.references(project, target)
  local everywhere
  if target.selector then
    everywhere = is_stylesheet(target.path) or target.selector.global
  else
    local rules = M.rules(project, target)
    if #rules == 0 then
      return {}
    end
    everywhere = #vim.tbl_filter(styles_everywhere, rules) > 0
  end
  local hits = {}
  for _, path in ipairs(paths_from(project, target.path)) do
    for _, use in ipairs(project[path].uses) do
      local reaches = everywhere or (path == target.path and not use.component)
      if use.name == target.name and reaches then
        table.insert(hits, { path = path, site = use })
      end
    end
  end
  return hits
end

return M
