local mappings = require("helpers.mappings")

-- :close rather than :cclose, so a location-list window closes too.
mappings.map("Close list", "n", "<Esc>", mappings.Cmd("close"), { buffer = true })
