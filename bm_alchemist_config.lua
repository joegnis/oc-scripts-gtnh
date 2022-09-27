local component = require "component"
local sides = require "sides"

-- To specify an OC component by its ID:
-- component.proxy("ID")
-- You can copy ID to system clipboard by Ctrl-Shift-Right-click
-- a component while holding an Analyzer from OC.
local config = {
    -- Components
    meInterface = component.me_interface,
    transposer = component.transposer,
    transposerSideChemset = sides.west,
    transposerSideInput = sides.south,
}

return config
