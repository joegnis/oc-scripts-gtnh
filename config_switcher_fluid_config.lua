local component = require "component"
local sides = require "sides"

local config = {
    transposerInputHatch = component.proxy("ID1"),
    sideInputHatch = sides.down,
    transposerMEChest = component.proxy("ID2"),
    sideMEChest = sides.west,
    sideOutputChest = sides.south,
    meInterface = component.me_interface,

    numConsecutiveEmptyCycles = 3,
    ---Get item info by running snippets/get_item_info.lua.
    ---Items are found if their pattern is found in any substring.
    ---Molds and Shapes share the same "name",
    ---so we have to find by different fields
    ---@type {field: string, pattern: string}[]
    itemsToIgnore = {
        -- programmed circuit
        { field = "name",  pattern = "gt.integrated_circuit" },
        -- programmed bio circuit
        { field = "name",  pattern = "item.BioRecipeSelector" },
        -- programmed breakthrough circuit
        { field = "name",  pattern = "item.T3RecipeSelector" },
        -- molds
        { field = "label", pattern = "Mold" },
        -- shapes
        { field = "label", pattern = "Shape" },
    },
    debug = false
}

return config
