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
    bloodAltar = component.blood_altar,
    -- Transposer Input
    transposerInputInputSide = sides.north,
    ---Side of output chest connected to altar
    transposerInputOutputSide = sides.west,
    transposerInputOrbSide = sides.top,
    -- Transposer Altar
    transposerAltarAltarSide = sides.west,
    transposerAltarOutputSide = sides.north,
    transposerAltarOrbSide = sides.top,
    -- Hard-coded blood and tier requirement for each recipe
    ---@alias BMRecipeRequirement {blood: integer, tier: integer}
    ---@type table<string, BMRecipeRequirement>
    recipeRequirements = {
        ["bucket of life"] = { blood = 1000, tier = 1},
        ["blood tnt"] = { blood = 10000, tier = 3 },
        ["blood cake"] = { blood = 10000, tier = 3 },
        ["blood infused iron ingot"] = { blood = 6000, tier = 3 },
        ["blood orange"] = { blood = 200, tier = 1 },
        ["blood cookie"] = { blood = 2000, tier = 1 },
        ["blood money x1"] = { blood = 10000, tier = 3 },
        ["bloodthorn"] = { blood = 15000, tier = 4 },
        ["blood infused wood"] = { blood = 5000, tier = 2 },
        ["blood stained glass"] = { blood = 200, tier = 1 },
        ["blood stained ice"] = { blood = 400, tier = 1 },
        ["blood stained packed ice"] = { blood = 600, tier = 1 },
        ["blood infused iron block"] = { blood = 64000, tier = 4 },
        ["blood infused glowstone"] = { blood = 28000, tier = 4 },
        ["blood infused diamond (active)"] = { blood = 120000, tier = 4 },
        ["blood diamond"] = { blood = 12000, tier = 4 },
        ["blood infused glowstone dust"] = { blood = 7000, tier = 3 },
        ["blood burned string"] = { blood = 5000, tier = 2 },
        ["soul fragment"] = { blood = 100000, tier = 4 },
        ["weak blood orb"] = { blood = 5000, tier = 1 },
        ["apprentice blood orb"] = { blood = 10000, tier = 2 },
        ["magician's blood orb"] = { blood = 30000, tier = 3 },
        ["master blood orb"] = { blood = 60000, tier = 4 },
        ["archmage's blood orb"] = { blood = 120000, tier = 5 },
        ["transcendent blood orb"] = { blood = 300000, tier = 6 },
        ["blank slate"] = { blood = 1000, tier = 1 },
        ["reinforced slate"] = { blood = 2500, tier = 2 },
        ["imbued slate"] = { blood = 7500, tier = 3 },
        ["demonic slate"] = { blood = 20000, tier = 4 },
        ["ethereal slate"] = { blood = 60000, tier = 5 },
        -- TODO: Needs to read content of cell
        ["universal fluid cell"] = { blood = 1000, tier = 1 },
        ["potion flask"] = { blood = 4000, tier = 2 },
        ["unbound crystal"] = { blood = 5000, tier = 2 },
        ["dagger of sacrifice"] = { blood = 10000, tier = 2 },
        ["weak activation crystal"] = { blood = 20000, tier = 3 },
        ["filled socket"] = { blood = 40000, tier = 3 },
        ["elemental inscription tool: water"] = { blood = 5000, tier = 3 },
        ["elemental inscription tool: fire"] = { blood = 5000, tier = 3 },
        ["elemental inscription tool: earth"] = { blood = 5000, tier = 3 },
        ["elemental inscription tool: air"] = { blood = 5000, tier = 3 },
        ["elemental inscription tool: dusk"] = { blood = 10000, tier = 4 },
        ["elemental inscription tool: dawn"] = { blood = 10000, tier = 6 },
        ["ender shard"] = { blood = 5000, tier = 4 },
        ["enhanced teleposition focus"] = { blood = 20000, tier = 4 },
        ["blood-soaked thaumium block"] = { blood = 5000, tier = 2 },
        ["blood-soaked void block"] = { blood = 10000, tier = 3 },
        ["blood-soaked ichorium block"] = { blood = 50000, tier = 5 },
        ["bound diamond"] = { blood = 10000, tier = 5 },
        ["blood rod"] = { blood = 50000, tier = 4 },
    },
}

return config
