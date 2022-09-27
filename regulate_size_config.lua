local component = require "component"
local sides = require "sides"

-- To specify an OC component by its ID:
-- component.proxy("ID")
-- You can copy ID to system clipboard by Ctrl-Shift-Right-click
-- a component while holding an Analyzer.
local config = {
    -- Regulator array
    -- Fill in transposer IDs and add more as you want
    -- Transposer ID does not need to be unique
    regulators = {
        {
            transposer = "ID1",
            sideToSizes = { [sides.north] = 7, [sides.west] = 11, [sides.south] = 13 },
            outSide = sides.top,
        },
    }
}

return config
