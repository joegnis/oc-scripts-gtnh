local component = require "component"
local sides = require "sides"

-- To specify an OC component by its ID:
-- component.proxy("ID")
-- You can copy ID to system clipboard by Ctrl-Shift-Right-click
-- a component while holding an Analyzer from OC.
local config = {
    -- Components
    -- Change this
    transposerInput = component.proxy("ID1"),
    -- Change this
    transposerAltar = component.proxy("ID2"),
    meInterface = component.me_interface,
    -- Transposer Input
    transposerInputInputSide = sides.north,
    ---Side of output chest connected to altar
    transposerInputOutputSide = sides.west,
    transposerInputOrbSide = sides.top,
    -- Transposer Altar
    transposerAltarAltarSide = sides.west,
    transposerAltarOutputSide = sides.north,
    transposerAltarOrbSide = sides.south,
}

return config
