local parse = require("plugins.svelte-css.parse")
local resolve = require("plugins.svelte-css.resolve")

---Three components and a stylesheet. `local` is scoped in A and B, `card` lives in the
---stylesheet and in B's `:global(…)`, `tag` only in B's `:global(…)`, `own` is defined
---only in A, and no rule styles `plain`.
---@return svelte_css.Project
local function project()
  return {
    ["/p/A.svelte"] = parse.parse(
      table.concat({
        '<div class="card local own tag"></div>',
        "<style>",
        "  .local { a: b }",
        "  .own { c: d }",
        "</style>",
      }, "\n"),
      "svelte"
    ),
    ["/p/B.svelte"] = parse.parse(
      table.concat({
        '<p class="card local plain"></p>',
        "<style>",
        "  .local { e: f }",
        "  .shell :global(.card) { g: h }",
        "  :global(.tag) { k: l }",
        "</style>",
      }, "\n"),
      "svelte"
    ),
    ["/p/C.svelte"] = parse.parse('<i class="tag"></i>', "svelte"),
    ["/p/atoms.css"] = parse.parse(".card,\n.card:hover { i: j }\n", "css"),
  }
end

---Each hit as `"<file>:<row>"`, rows 0-based.
---@param hits svelte_css.Hit[]
---@return string[]
local function where(hits)
  return vim.tbl_map(function(hit)
    return vim.fs.basename(hit.path) .. ":" .. hit.site.range[1]
  end, hits)
end

describe("svelte-css.resolve", function()
  describe("at", function()
    it("finds the class used under the cursor", function()
      local target = resolve.at(project(), "/p/A.svelte", 0, 18)
      assert.same({ "local", false }, { target and target.name, target and target.selector ~= nil })
    end)

    it("finds the selector under the cursor", function()
      local target = resolve.at(project(), "/p/A.svelte", 2, 4)
      assert.same({ "local", true }, { target and target.name, target and target.selector ~= nil })
    end)

    it("finds nothing between classes", function()
      assert.is_nil(resolve.at(project(), "/p/A.svelte", 0, 16))
    end)
  end)

  describe("definitions", function()
    it("gives a scoped class only its own component's rule", function()
      local target = assert(resolve.at(project(), "/p/A.svelte", 0, 18))
      assert.same({ "A.svelte:2" }, where(resolve.definitions(project(), target)))
    end)

    it("adds stylesheet rules and other components' :global rules", function()
      local target = assert(resolve.at(project(), "/p/A.svelte", 0, 12))
      assert.same({ "B.svelte:3", "atoms.css:0" }, where(resolve.definitions(project(), target)))
    end)

    it("lists a rule once however many of its selectors name the class", function()
      local target = assert(resolve.at(project(), "/p/atoms.css", 1, 2))
      assert.same({ "atoms.css:0", "B.svelte:3" }, where(resolve.definitions(project(), target)))
    end)

    it("finds a class only another component's :global rule styles", function()
      local target = assert(resolve.at(project(), "/p/C.svelte", 0, 10))
      assert.same({ "B.svelte:4" }, where(resolve.definitions(project(), target)))
    end)

    it("finds the rules in a project of ten thousand files", function()
      local files = project()
      for i = 1, 10000 do
        files["/p/many/" .. i .. ".svelte"] = { definitions = {}, uses = {} }
      end
      local target = assert(resolve.at(files, "/p/A.svelte", 0, 18))
      assert.same({ "A.svelte:2" }, where(resolve.definitions(files, target)))
    end)
  end)

  describe("references", function()
    it("keeps a scoped selector's uses to its own component", function()
      local target = assert(resolve.at(project(), "/p/B.svelte", 2, 4))
      assert.same({ "B.svelte:0" }, where(resolve.references(project(), target)))
    end)

    it("finds a stylesheet selector's uses in every component", function()
      local target = assert(resolve.at(project(), "/p/atoms.css", 0, 2))
      assert.same({ "A.svelte:0", "B.svelte:0" }, where(resolve.references(project(), target)))
    end)

    it("finds a :global selector's uses in every component", function()
      local target = assert(resolve.at(project(), "/p/B.svelte", 3, 19))
      assert.same({ "B.svelte:0", "A.svelte:0" }, where(resolve.references(project(), target)))
    end)

    it("keeps a use of a scoped class to its own component", function()
      local target = assert(resolve.at(project(), "/p/A.svelte", 0, 18))
      assert.same({ "A.svelte:0" }, where(resolve.references(project(), target)))
    end)

    it("widens a use of a stylesheet class to every component", function()
      local target = assert(resolve.at(project(), "/p/A.svelte", 0, 12))
      assert.same({ "A.svelte:0", "B.svelte:0" }, where(resolve.references(project(), target)))
    end)

    it("widens a use of a class a :global rule styles to every component", function()
      local target = assert(resolve.at(project(), "/p/C.svelte", 0, 10))
      assert.same({ "C.svelte:0", "A.svelte:0" }, where(resolve.references(project(), target)))
    end)

    it("finds no uses of a class no rule styles", function()
      local target = assert(resolve.at(project(), "/p/B.svelte", 0, 22))
      assert.same({}, resolve.references(project(), target))
    end)
  end)

  describe("a class on a component's tag", function()
    ---A page that passes `primary` and `card` to a component, and styles `primary` itself.
    ---@return svelte_css.Project
    local function page()
      return {
        ["/p/Page.svelte"] = parse.parse(
          table.concat({
            '<Button class="primary card" />',
            '<b class="primary"></b>',
            "<style>",
            "  .primary { a: b }",
            "</style>",
          }, "\n"),
          "svelte"
        ),
        ["/p/atoms.css"] = parse.parse(".card { i: j }", "css"),
      }
    end

    it("gets no rules from its own file's scoped style", function()
      local target = assert(resolve.at(page(), "/p/Page.svelte", 0, 16))
      assert.same({}, resolve.definitions(page(), target))
    end)

    it("gets the stylesheet's rules", function()
      local target = assert(resolve.at(page(), "/p/Page.svelte", 0, 24))
      assert.same({ "atoms.css:0" }, where(resolve.definitions(page(), target)))
    end)

    it("is left out of its file's scoped selector's uses", function()
      local target = assert(resolve.at(page(), "/p/Page.svelte", 3, 4))
      assert.same({ "Page.svelte:1" }, where(resolve.references(page(), target)))
    end)
  end)

  describe("a class that only qualifies another element", function()
    ---`shell` is styled by App's `.shell` rule, and only qualifies `.bar` in App and
    ---`.card` in the stylesheet. Other uses `shell` too.
    ---@return svelte_css.Project
    local function app()
      return {
        ["/q/App.svelte"] = parse.parse(
          table.concat({
            '<main class="shell"></main>',
            "<style>",
            "  .shell { a: b }",
            "  .shell > .bar { c: d }",
            "</style>",
          }, "\n"),
          "svelte"
        ),
        ["/q/Other.svelte"] = parse.parse('<div class="shell"></div>', "svelte"),
        ["/q/layout.css"] = parse.parse(".shell .card { e: f }", "css"),
      }
    end

    it("gets only the rules whose subject carries it", function()
      local target = assert(resolve.at(app(), "/q/App.svelte", 0, 13))
      assert.same({ "App.svelte:2" }, where(resolve.definitions(app(), target)))
    end)

    it("widens its uses to every component when a stylesheet rule names it anywhere", function()
      local target = assert(resolve.at(app(), "/q/App.svelte", 0, 13))
      assert.same({ "App.svelte:0", "Other.svelte:0" }, where(resolve.references(app(), target)))
    end)

    it("is still a cursor target in a selector that qualifies another element", function()
      local target = assert(resolve.at(app(), "/q/App.svelte", 3, 4))
      assert.same({ "App.svelte:0" }, where(resolve.references(app(), target)))
    end)
  end)

  describe("a class whose rules only qualify other elements", function()
    ---`wrapper` sits only ahead of `:global(.child)` in Segmented's scoped style, and
    ---Other uses it too.
    ---@return svelte_css.Project
    local function segmented()
      return {
        ["/w/Segmented.svelte"] = parse.parse(
          table.concat({
            '<div class="wrapper"></div>',
            "<style>",
            "  .wrapper :global(.child) { a: b }",
            "</style>",
          }, "\n"),
          "svelte"
        ),
        ["/w/Other.svelte"] = parse.parse('<div class="wrapper"></div>', "svelte"),
      }
    end

    it("gets no rules from its markup", function()
      local target = assert(resolve.at(segmented(), "/w/Segmented.svelte", 0, 13))
      assert.same({}, resolve.definitions(segmented(), target))
    end)

    it("finds the same uses from its markup as from its selector", function()
      local markup = assert(resolve.at(segmented(), "/w/Segmented.svelte", 0, 13))
      local selector = assert(resolve.at(segmented(), "/w/Segmented.svelte", 2, 4))
      assert.same({ "Segmented.svelte:0" }, where(resolve.references(segmented(), markup)))
      assert.same({ "Segmented.svelte:0" }, where(resolve.references(segmented(), selector)))
    end)
  end)
end)
