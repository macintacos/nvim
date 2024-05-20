local cmp = require("cmp")

cmp.setup.buffer({
    sources = cmp.config.sources({
        { name = "conventionalcommits" },
        { name = "buffer" },
    }),
})
