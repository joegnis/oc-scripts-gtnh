local event = require "event"
local sides = require "sides"

local config = require "blood_altar_config"
local utils = require "utils"

local TRANSPOSER_INPUT = config.transposerInput
local TRANSPOSER_ALTAR = config.transposerAltar
local ME_INTERFACE = config.meInterface

local TRANSPOSER_INPUT_SIDE_INPUT = config.transposerInputInputSide
local TRANSPOSER_INPUT_SIDE_OUTPUT = config.transposerInputOutputSide
local TRANSPOSER_INPUT_SIDE_ORB = config.transposerInputOrbSide
local TRANSPOSER_ALTAR_SIDE_ALTAR = config.transposerAltarAltarSide
local TRANSPOSER_ALTAR_SIDE_OUTPUT = config.transposerAltarOutputSide
local TRANSPOSER_ALTAR_SIDE_ORB = config.transposerAltarOrbSide

local DESCRIPTION = [[
Restart this program if patterns has changed. Press Ctrl-C to stop.
You can put your blood orb in the altar. It will be saved in the red chest during crafting and put back after that.
]]

local DEBUG = false

--[[
    Scans input box, and returns the name of output and the slot input resides in

    Returns "", 0 if no item is found.
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
    return "", 0
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

--[[
    Retrieves any blood orb in the altar and put it in the orb chest

    Does nothing if there is no orb in the altar
]]
local function saveOrb(transposerAltar, sideAltar, sideOrb)
    local itemInfo = utils.firstItem(transposerAltar, sideAltar)
    if itemInfo and string.find(string.lower(itemInfo.name), "blood orb") ~= nil then
        transposerAltar.transferItem(sideAltar, sideOrb, 1, 1, utils.firstAvailableSlot(transposerAltar, sideOrb))
        print(string.format("Saved %s", itemInfo.name))
    end
end

--[[
    Retrieves any blood orb in the orb chest and put in in the input chest (to send to altar)

    Does nothing if there is no orb in the orb chest or the altar is occupied
]]
local function putOrb(transposerInput, sideOrb, sideInput, transposerAltar, sideAltar)
    local itemInfoOrbChest = utils.firstItem(transposerInput, sideOrb)
    local itemInfoAltar = utils.firstItem(transposerAltar, sideAltar)
    if not itemInfoAltar then
        if itemInfoOrbChest then
            if string.find(string.lower(itemInfoOrbChest.name), "blood orb") ~= nil then
                transposerInput.transferItem(sideOrb, sideInput, 1, itemInfoOrbChest.slot,
                    utils.firstAvailableSlot(transposerInput, sideInput))
                print("Put back blood orb")
            else
                print("Found an item that is not a blood orb so didn't put it")
            end
        end
    else
        if itemInfoOrbChest and not string.find(string.lower(itemInfoOrbChest.name), "blood orb") then
            print("Could not put an orb since alter was occupied")
        end
    end
end

local function main()
    print(DESCRIPTION)
    local patterns, inputToPatterns = utils.getPatternsInfo(ME_INTERFACE)
    print(string.format("Found %d patterns", utils.sizeOfTable(patterns)))

    local STATE = { IDLE = 0, ENTER = 1, INPUT = 2, WAIT = 3 }
    local state = STATE.IDLE
    local outputName = ""
    local inputSlot = 0
    while true do
        if state == STATE.IDLE then
            outputName, inputSlot = scanInputBox(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_INPUT, inputToPatterns)
            if outputName ~= "" then
                state = STATE.ENTER
            end
        elseif state == STATE.ENTER then
            saveOrb(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_ORB)
            state = STATE.INPUT
        elseif state == STATE.INPUT then
            getInput(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_INPUT, TRANSPOSER_INPUT_SIDE_OUTPUT, inputSlot)
            print("Waiting for output " .. outputName)
            state = STATE.WAIT
        elseif state == STATE.WAIT then
            if isAltarComplete(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, outputName) then
                getOutput(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_OUTPUT)

                outputName, inputSlot = scanInputBox(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_INPUT, inputToPatterns)
                if outputName ~= "" then
                    state = STATE.INPUT
                else
                    putOrb(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_ORB, TRANSPOSER_INPUT_SIDE_OUTPUT, TRANSPOSER_ALTAR,
                        TRANSPOSER_ALTAR_SIDE_ALTAR)
                    state = STATE.IDLE
                end
            end
        end
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
    saveOrb(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_ORB)
end

local function testSavePutOrb()
    putOrb(TRANSPOSER_INPUT, TRANSPOSER_INPUT_SIDE_ORB, TRANSPOSER_INPUT_SIDE_OUTPUT, TRANSPOSER_ALTAR,
        TRANSPOSER_ALTAR_SIDE_ALTAR)
end

main()
