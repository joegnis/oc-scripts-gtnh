local component = require "component"
local sides = require "sides"

-- To specify an OC component by its ID:
-- component.proxy("ID")
-- You can copy ID to system clipboard by Ctrl-Shift-Right-click
-- a component while holding an Analyzer from OC.
local config = {
    -- Components
    transposerInput = component.proxy("e53711f2-3432-4fe3-82ce-34816f69a536"),
    transposerAltar = component.proxy("33760ec9-6211-4299-8114-f660c3c274bb"),
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
