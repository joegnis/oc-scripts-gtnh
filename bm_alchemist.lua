local event = require "event"

local config = require "bm_alchemist_config"
local utils = require "utils"

local HELLO_MSG = [[
Assumes no items are split across different stacks so make sure to enable Blocking Mode on the ME interface.
Restart this program if patterns has changed. Press Ctrl-C to stop.
]]

local ME_INTERFACE = config.meInterface
local TRANSPOSER = config.transposer

local TRANSPOSER_SIDE_CHEMSET = config.transposerSideChemset
local TRANSPOSER_SIDE_INPUT = config.transposerSideInput

local function isPatternsInfoValid(patterns)
    local result = true
    for output, entry in pairs(patterns) do
        local countInputs = 0
        for _, count in pairs(entry.inputs) do
            countInputs = countInputs + count
        end
        if countInputs ~= 5 then
            print(string.format(
                "Pattern for %s is invalid since it does not have exactly 5 ingredients",
                output
            ))
            result = false
        end
    end
    return result
end

--[[
    Scans input box, and returns the name of output and a table of input items information

    e.g. It returns Potentia,
    {
        names = {"Energium Dust", "Vibrant Alloy Dust", "Strengthened Catalyst"},
        slots = {1, 2, 3},
        amounts = {2, 2, 1},
    }
    Returns nil, nil if no matched patterns were found.
    Assumes that no items are spilt across different stacks to make implementation simpler
]]
local function scanInputBox(transposerInput, sideInput, patternsInfo, outputLookup)
    local stacksInfo = utils.collectStacksInfo(transposerInput, sideInput)
    local possibleRecipes = {}
    local allInputsInfo = {}
    for input, entry in pairs(stacksInfo) do
        local inputSlot = entry.slots[1]
        local inputAmount = entry.amounts[1]

        local matchedOutputs = outputLookup[input]
        if matchedOutputs == nil then
            print("Skipped unkown item " .. input)
            goto continue
        end
        -- One input may be needed in multiple recipes
        for _, output in ipairs(matchedOutputs) do
            local patternInputsCounts = possibleRecipes[output] or utils.shallowCopy(patternsInfo[output].inputs)
            local requiredAmount = patternInputsCounts[input]
            possibleRecipes[output] = patternInputsCounts
            if inputAmount >= requiredAmount then
                patternInputsCounts[input] = nil

                local inputsInfo = allInputsInfo[output] or {
                    names = {},
                    slots = {},
                    amounts = {}
                }
                allInputsInfo[output] = inputsInfo
                inputsInfo.names[#inputsInfo.names + 1] = input
                inputsInfo.slots[#inputsInfo.slots + 1] = inputSlot
                inputsInfo.amounts[#inputsInfo.amounts + 1] = inputAmount

                if next(patternInputsCounts) == nil then
                    print("Found items to make " .. output)
                    return output, inputsInfo
                end
            end
        end

        ::continue::
    end
    return nil, nil
end

--[[
    Tests if chem set is empty (except for checking the orb slot)
]]
local function isChemsetEmpty(transposerInput, sideChemset)
    local stackIter = transposerInput.getAllStacks(sideChemset)
    local curStack = stackIter() -- Skips the first slot (orb slot)
    for _ = 1, 6 do
        curStack = stackIter()
        if next(curStack) ~= nil then
            return false
        end
    end
    return true
end

--[[
    Tests if chem set has an orb in it
]]
local function hasOrb(transposerInput, sideChemset)
    return transposerInput.getStackInSlot(sideChemset, 1) ~= nil
end

--[[
    Moves ingredients from the input chest to the chem set

    Assumes chem set is empty, and the number of ingredients in inputs_info is correct
]]
local function getInput(transposerInput, sideInput, sideChemset, inputsInfo)
    local chemSlot = 2
    local iInput = 1
    while chemSlot <= 6 do
        local inputSlot = inputsInfo.slots[iInput]
        local inputAmount = inputsInfo.amounts[iInput]
        for _ = 1, inputAmount do
            transposerInput.transferItem(sideInput, sideChemset, 1, inputSlot, chemSlot)
            chemSlot = chemSlot + 1
        end
        iInput = iInput + 1
    end
end

---@param args string[]
local function main(args)
    print(HELLO_MSG)
    local patterns, outputLookup = utils.getPatternsInfo(ME_INTERFACE)
    if not isPatternsInfoValid(patterns) then
        return
    end
    print(string.format("Found %d patterns", utils.sizeOfTable(patterns)))

    local outputName
    local inputsInfo
    local STATE = { IDLE = 0, WAIT_ORB = 1, INPUT = 2, WAIT_OUTPUT = 3 }
    local state = STATE.IDLE
    while true do
        if state == STATE.IDLE then
            outputName, inputsInfo = scanInputBox(TRANSPOSER, TRANSPOSER_SIDE_INPUT, patterns, outputLookup)
            if outputName and isChemsetEmpty(TRANSPOSER, TRANSPOSER_SIDE_CHEMSET) then
                if hasOrb(TRANSPOSER, TRANSPOSER_SIDE_CHEMSET) then
                    state = STATE.INPUT
                else
                    print("No orb in the chem set. Waiting...")
                    state = STATE.WAIT_ORB
                end
            end
        elseif state == STATE.INPUT then
            getInput(TRANSPOSER, TRANSPOSER_SIDE_INPUT, TRANSPOSER_SIDE_CHEMSET, inputsInfo)
            print("Waiting for output")
            state = STATE.WAIT_OUTPUT
        elseif state == STATE.WAIT_ORB then
            if hasOrb(TRANSPOSER, TRANSPOSER_SIDE_CHEMSET) then
                state = STATE.INPUT
            end
        elseif state == STATE.WAIT_OUTPUT then
            if isChemsetEmpty(TRANSPOSER, TRANSPOSER_SIDE_CHEMSET) then
                print(outputName .. " done")
                state = STATE.IDLE
            end
        end

        local id = event.pull(0.5, "interrupted")
        if id ~= nil then
            break
        end
    end
end

local function testGetPatterns()
    local patterns, _ = utils.getPatternsInfo(ME_INTERFACE)
    print(utils.tableToString(patterns))
end

local function testValidatePatterns()
    local patterns, _ = utils.getPatternsInfo(ME_INTERFACE)
    print(isPatternsInfoValid(patterns))
end

local function testGetOutputLookup()
    local _, outputLookup = utils.getPatternsInfo(ME_INTERFACE)
    print(utils.tableToString(outputLookup))
end

local function testScanInputBox()
    local patterns, outputLookup = utils.getPatternsInfo(ME_INTERFACE)
    local output, inputInfo = scanInputBox(TRANSPOSER, TRANSPOSER_SIDE_INPUT, patterns, outputLookup)
    print(output)
    print(utils.tableToString(inputInfo))
end

local function testIsChemSetEmpty()
    print(isChemsetEmpty(TRANSPOSER, TRANSPOSER_SIDE_CHEMSET))
end

local function testHasOrb()
    print(hasOrb(TRANSPOSER, TRANSPOSER_SIDE_CHEMSET))
end

local function testGetInput()
    local patterns, outputLookup = utils.getPatternsInfo(ME_INTERFACE)
    local _, inputInfo = scanInputBox(TRANSPOSER, TRANSPOSER_SIDE_INPUT, patterns, outputLookup)
    getInput(TRANSPOSER, TRANSPOSER_SIDE_INPUT, TRANSPOSER_SIDE_CHEMSET, inputInfo)
end

main({ ... })
