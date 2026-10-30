local parse = require("plugins.svelte-css.parse")

---Each site as `{ name, range }`, so a spec can compare where classes were found.
---@param sites svelte_css.Site[]
---@return table[]
local function located(sites)
  return vim.tbl_map(function(site)
    return { site.name, site.range }
  end, sites)
end

---@param sites svelte_css.Site[]
---@return string[]
local function names(sites)
  return vim.tbl_map(function(site)
    return site.name
  end, sites)
end

---@param definitions svelte_css.Definition[]
---@return string[]
local function rules(definitions)
  return vim.tbl_map(function(def)
    return def.rule
  end, definitions)
end

---@param definitions svelte_css.Definition[]
---@return boolean[]
local function globals(definitions)
  return vim.tbl_map(function(def)
    return def.global
  end, definitions)
end

describe("svelte-css.parse", function()
  describe("svelte markup", function()
    it("finds each class in a class attribute and a class: directive", function()
      local classes = parse.parse('<div class="a b-c" class:active={on}></div>', "svelte")
      assert.same({
        { "a", { 0, 12, 0, 13 } },
        { "b-c", { 0, 14, 0, 17 } },
        { "active", { 0, 25, 0, 31 } },
      }, located(classes.uses))
    end)

    it("skips every token that carries an interpolation", function()
      local classes = parse.parse([[<p class="x btn-{size} {on ? 'p q' : ''} y"></p>]], "svelte")
      assert.same({ "x", "y" }, names(classes.uses))
    end)

    it("locates a class on a wrapped line of the attribute", function()
      local classes = parse.parse('<p class="a\n  b"></p>', "svelte")
      assert.same({ { "a", { 0, 10, 0, 11 } }, { "b", { 1, 2, 1, 3 } } }, located(classes.uses))
    end)

    it("reads an unquoted class attribute", function()
      local classes = parse.parse("<p class=plain></p>", "svelte")
      assert.same({ { "plain", { 0, 9, 0, 14 } } }, located(classes.uses))
    end)

    it("ignores other attributes", function()
      local classes = parse.parse('<p id="a" data-class="b"></p>', "svelte")
      assert.same({}, classes.uses)
    end)

    it("marks the uses on a component's tag, capitalized or dotted", function()
      local classes = parse.parse('<Button class="a" /><ui.button class="b" /><div class="c"></div>', "svelte")
      assert.same(
        { true, true, false },
        vim.tbl_map(function(use)
          return use.component
        end, classes.uses)
      )
    end)
  end)

  describe("svelte style block", function()
    local source = table.concat({
      '<b class="x"></b>',
      "<style>",
      "  .x {",
      "    color: red;",
      "  }",
      "  .shell > :global(.g) { c: d }",
      "</style>",
    }, "\n")

    it("finds class selectors at their place in the component", function()
      local classes = parse.parse(source, "svelte")
      assert.same({
        { "x", { 2, 3, 2, 4 } },
        { "shell", { 5, 3, 5, 8 } },
        { "g", { 5, 20, 5, 21 } },
      }, located(classes.definitions))
    end)

    it("marks only the classes inside :global() as global", function()
      local classes = parse.parse(source, "svelte")
      assert.same({ false, false, true }, globals(classes.definitions))
    end)

    it("keeps each rule's text, dedented", function()
      local classes = parse.parse(source, "svelte")
      local shell = ".shell > :global(.g) { c: d }"
      assert.same({ ".x {\n  color: red;\n}", shell, shell }, rules(classes.definitions))
    end)

    it("does not count selectors as uses", function()
      local classes = parse.parse(source, "svelte")
      assert.same({ "x" }, names(classes.uses))
    end)

    it("keeps a rule that opens on the <style> line flush left", function()
      local classes = parse.parse("<style>.a {\n  color: red;\n}</style>", "svelte")
      assert.same({ ".a {\n  color: red;\n}" }, rules(classes.definitions))
    end)

    it("marks every class inside a :global() that follows a tag", function()
      local classes = parse.parse("<style>p:global(.big.red) { a: b }</style>", "svelte")
      assert.same({ true, true }, globals(classes.definitions))
    end)

    it("marks only the argument of a :global() that follows a class", function()
      local classes = parse.parse("<style>.a:global(.b) { a: b }</style>", "svelte")
      assert.same({ false, true }, globals(classes.definitions))
    end)
  end)

  describe("stylesheet", function()
    local source = table.concat({
      ".card,",
      "button.card:hover {",
      "  color: red;",
      "}",
      "@media (min-width: 1px) {",
      "  .inner { a: b }",
      "}",
    }, "\n")

    it("finds class selectors in compound, pseudo-class, and nested rules", function()
      local classes = parse.parse(source, "css")
      assert.same({
        { "card", { 0, 1, 0, 5 } },
        { "card", { 1, 7, 1, 11 } },
        { "inner", { 5, 3, 5, 8 } },
      }, located(classes.definitions))
    end)

    it("gives every selector of a rule that rule's text", function()
      local classes = parse.parse(source, "css")
      local rule = ".card,\nbutton.card:hover {\n  color: red;\n}"
      assert.same({ rule, rule, ".inner { a: b }" }, rules(classes.definitions))
    end)
  end)

  describe("selector subject", function()
    ---Each class selector's name, and whether its rule styles the element carrying it.
    ---@param css string
    ---@return table[]
    local function subjects(css)
      return vim.tbl_map(function(def)
        return { def.name, def.subject }
      end, parse.parse(css, "css").definitions)
    end

    it("is the rightmost compound across each combinator", function()
      assert.same({
        { "a", false },
        { "b", true },
        { "c", false },
        { "d", true },
        { "e", false },
        { "f", true },
        { "g", false },
        { "h", true },
      }, subjects(".a .b, .c > .d, .e + .f, .g ~ .h {}"))
    end)

    it("takes in every class of a compound", function()
      assert.same({ { "a", true }, { "b", true }, { "c", true } }, subjects(".a:hover, .b.c {}"))
    end)

    it("reaches into :global, :is and :where, but not :not or :has", function()
      assert.same({
        { "x", false },
        { "a", true },
        { "b", true },
        { "c", true },
        { "d", true },
        { "e", false },
        { "f", true },
        { "g", false },
      }, subjects(".x > :global(.a), :is(.b), :where(.c), .d:not(.e), .f:has(.g) {}"))
    end)

    it("is judged by each nested rule's own selector", function()
      assert.same(
        { { "a", true }, { "b", true }, { "c", false }, { "d", true } },
        subjects(".a { .b { x: y } .c .d { x: y } }")
      )
    end)
  end)
end)
