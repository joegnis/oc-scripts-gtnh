local event = require "event"
local sides = require "sides"

local config = require "blood_altar_config"
local utils = require "utils"

local TRANSPOSER_INPUT = config.transposerInput
local TRANSPOSER_ALTAR = config.transposerAltar
local ME_INTERFACE = config.meInterface
local BLOOD_ALTAR = config.bloodAltar

local TRANSPOSER_INPUT_SIDE_INPUT = config.transposerInputInputSide
local TRANSPOSER_INPUT_SIDE_OUTPUT = config.transposerInputOutputSide
local TRANSPOSER_INPUT_SIDE_ORB = config.transposerInputOrbSide
local TRANSPOSER_ALTAR_SIDE_ALTAR = config.transposerAltarAltarSide
local TRANSPOSER_ALTAR_SIDE_OUTPUT = config.transposerAltarOutputSide
local TRANSPOSER_ALTAR_SIDE_ORB = config.transposerAltarOrbSide

local RECIPE_REQUIREMENTS = config.recipeRequirements

local HELLO_MSG = [[
Restart this program if patterns has changed. Press Ctrl-C to stop.
You can put your blood orb in the altar. It will be saved in the orb chest during crafting and put back after that.
]]

local DEBUG = false

--[[
    Scans input box, and returns the name of output and the slot input resides in

    Returns nil,nil if no item is found.
    Blood altar only takes one kind of items a time, so it is simpler.
]]
local function scanInputBox(transposerInput, side, inputToPatterns)
    local stacksInfo = utils.collectStacksInfo(transposerInput, side)
    for name, entry in pairs(stacksInfo) do
        local matchedOutputs = inputToPatterns[name]
        if matchedOutputs ~= nil then
            print(string.format('Found item %s to make %s', name, table.concat(matchedOutputs, ", ")))
            local slot = entry.slots[1]
            if DEBUG then
                print(string.format("Found item %s in slot %d", name, slot))
            end
            return matchedOutputs[1], slot
        end
    end
    return nil, nil
end

local function getInput(transposerInput, fromSide, toSide, slot)
    transposerInput.transferItem(fromSide, toSide, 1, slot, utils.firstAvailableSlot(transposerInput, toSide))
end

local function isAltarComplete(transposerAltar, sideAltar, nameOutput)
    local stack = transposerAltar.getStackInSlot(sideAltar, 1)
    if stack ~= nil then
        if stack.label == nameOutput then
            print(nameOutput .. " done")
            return true
        end
    end
    return false
end

local function getOutput(transposerAltar, sideAltar, sideOutput)
    transposerAltar.transferItem(sideAltar, sideOutput, 1, 1, utils.firstAvailableSlot(transposerAltar, sideOutput))
end

---Finds the first blood orb in an inventory, returns its slot number and stack info if found
---@param transposer any
---@param sideInventory integer
---@return integer? slot
---@return StackInfo? orb
local function getOrbFromInventory(transposer, sideInventory)
    local stackInfo = utils.firstStack(transposer, sideInventory)
    if stackInfo and string.find(stackInfo.name, "^AWWayofTime:.*BloodOrb$") ~= nil then
        return stackInfo.slot, stackInfo
    end
end

--[[
    Retrieves any blood orb in the altar and put it in the orb chest

    Does nothing if there is no orb in the altar
]]
---@param transposerAltar any
---@param sideAltar integer
---@param sideOrb integer
local function saveOrbFromAltar(transposerAltar, sideAltar, sideOrb)
    local orbSlot, orb = getOrbFromInventory(transposerAltar, sideAltar)
    if orbSlot and orb then
        transposerAltar.transferItem(sideAltar, sideOrb, 1, orbSlot)
        print(string.format("Saved %s", orb.label))
    end
end

--[[
    Retrieves the first blood orb from the orb chest and put in in the output chest (to send to altar)

    Does nothing if there is no orb in the orb chest or the altar is occupied
]]
---@param transposerInput any
---@param sideOrb integer
---@param sideOutput integer
---@param transposerAltar any
---@param sideAltar integer
local function putOrbOnAltar(transposerInput, sideOrb, sideOutput, transposerAltar, sideAltar)
    local orbSlot, orb = getOrbFromInventory(transposerInput, sideOrb)
    if orbSlot and orb and not next(transposerAltar.getAllStacks(sideAltar)()) then
        local transferred = transposerInput.transferItem(sideOrb, sideOutput, 1, orbSlot)
        if transferred > 0 then
            print(string.format("Put %s on Altar", orb.label))
        end
    end
end

---@param bloodAltar any
---@param requiredBlood integer
---@return boolean
local function isBloodEnough(bloodAltar, requiredBlood)
    return bloodAltar.getCurrentBlood() >= requiredBlood
end

---@param bloodAltar any
---@param requiredTier integer
---@return boolean
local function isTierEnough(bloodAltar, requiredTier)
    return bloodAltar.getTier() >= requiredTier
end

---Checks provided patterns info. Exits if anything is wrong.
---@param bloodAltar any
---@param patternsInfo table<string, PatternInfo>
---@param recipeRequirements table<string, BMRecipeRequirement>
local function checkPatterns(bloodAltar, patternsInfo, recipeRequirements)
    local msg = {}
    for output, _ in pairs(patternsInfo) do
        local requirement = recipeRequirements[string.lower(output)]
        if not isTierEnough(bloodAltar, requirement.tier) then
            msg[#msg + 1] = string.format(
                "Pattern of %s needs tier (%d) higher than current one's.",
                output, requirement.tier
            )
        end
    end
    if #msg > 0 then
        io.stderr:write(table.concat(msg, "\n"))
        os.exit(false)
    end
end

local function main()
    print(HELLO_MSG)
    local patterns, inputToPatterns = utils.getPatternsInfo(ME_INTERFACE)
    print(string.format("Found %d patterns", utils.sizeOfTable(patterns)))
    checkPatterns(BLOOD_ALTAR, patterns, RECIPE_REQUIREMENTS)

    local STATE = { IDLE = 0, INPUT = 1, WAIT = 2, WAIT_FOR_BLOOD = 3 }
    local state = STATE.IDLE
    ---@type string?
    local outputName
    ---@type integer?
    local inputSlot
    local requirement
    while true do
        if state == STATE.IDLE then
            outputName, inputSlot = scanInputBox(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_INPUT, inputToPatterns)
            if outputName then
                local lowerName = string.lower(outputName)
                if lowerName == "universal fluid cell" then
                    print("WARNING: Universal Fluid Cell is not supported yet.")
                end
                requirement = RECIPE_REQUIREMENTS[lowerName]
                if requirement then
                    local requiredBlood = requirement.blood
                    if not isBloodEnough(BLOOD_ALTAR, requiredBlood) then
                        print(string.format("Not enough blood in Altar (%d needed). Waiting...", requiredBlood))
                        state = STATE.WAIT_FOR_BLOOD
                        goto continue
                    end
                else
                    print(string.format(
                        "Blood requirement for %s was not found. Putting it onto Altar regardlessly.",
                        outputName
                    ))
                end
                state = STATE.INPUT
            else
                putOrbOnAltar(
                    TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_ORB, TRANSPOSER_INPUT_SIDE_OUTPUT,
                    TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR
                )
            end
        elseif state == STATE.INPUT then
            saveOrbFromAltar(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_ORB)
            getInput(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_INPUT, TRANSPOSER_INPUT_SIDE_OUTPUT, inputSlot)
            print("Waiting for output " .. outputName)
            state = STATE.WAIT
        elseif state == STATE.WAIT then
            if isAltarComplete(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, outputName) then
                getOutput(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_OUTPUT)
                state = STATE.IDLE
            end
        elseif state == STATE.WAIT_FOR_BLOOD then
            if isBloodEnough(BLOOD_ALTAR, requirement.blood) then
                state = STATE.INPUT
            end
        end

        ::continue::
        local id = event.pull(0.5, "interrupted")
        if id ~= nil then
            break
        end
    end
end

local function testScanInputBox()
    local _, inputToPatterns = utils.getPatternsInfo(ME_INTERFACE)
    print(scanInputBox(TRANSPOSER_INPUT, sides.south, inputToPatterns))
end

local function testGetInput()
    getInput(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_INPUT, TRANSPOSER_INPUT_SIDE_OUTPUT, 1)
end

local function testIsAltarComplete()
    print(isAltarComplete(TRANSPOSER_ALTAR, sides.east, "Master Blood Orb"))
end

local function testGetOutput()
    getOutput(TRANSPOSER_ALTAR, sides.east, sides.south)
end

local function testSaveOrb()
    saveOrbFromAltar(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_ORB)
end

local function testPutOrb()
    putOrbOnAltar(
        TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_ORB, TRANSPOSER_INPUT_SIDE_OUTPUT,
        TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR
    )
end

local function testSavePutOrb()
    putOrbOnAltar(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_ORB, TRANSPOSER_INPUT_SIDE_OUTPUT, TRANSPOSER_ALTAR,
        TRANSPOSER_ALTAR_SIDE_ALTAR)
end

local function testIsBloodEnough()
    print(isBloodEnough(BLOOD_ALTAR, 100000))
end

main()
