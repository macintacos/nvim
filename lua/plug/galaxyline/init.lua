-- Orchestrates my galaxyline config. Imported in lua/config.lua

-- Need to add the PLUG_PATH so that we understand where to get the below modules.
package.path = PLUG_PATH .. '/galaxyline/?.lua;' .. package.path

-- "Main" line, shown on the active buffer
require("section_left")
require("section_right")
require("section_mid")

-- -- "Short/Inactive" line, shown when the line is rendered on an inactive or "short" buffer.
-- -- Buffers that are "short" are things like debuggers, file explorers, etc. (set at the top of the file)
require("section_short_inactive")