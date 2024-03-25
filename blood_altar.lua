local event = require "event"
local sides = require "sides"

local config = require "blood_altar_config"
local utils = require "utils"

local TRANSPOSER_ME = config.transposerME
local TRANSPOSER_ALTAR = config.transposerAltar
local ME_INTERFACE = config.meInterface
local BLOOD_ALTAR = config.bloodAltar

local TRANSPOSER_ME_SIDE_INPUT = config.transposerMEInputSide
local TRANSPOSER_ME_SIDE_OUTPUT = config.transposerMEOutputSide
local TRANSPOSER_ME_SIDE_ORB = config.transposerMEOrbSide
local TRANSPOSER_ALTAR_SIDE_ALTAR = config.transposerAltarAltarSide
local TRANSPOSER_ALTAR_SIDE_OUTPUT = config.transposerAltarOutputSide
local TRANSPOSER_ALTAR_SIDE_ORB = config.transposerAltarOrbSide

local RECIPE_REQUIREMENTS = config.recipeRequirements

local HELLO_MSG = [[
Restart this program if patterns has changed. Press Ctrl-C to stop.
You can put your blood orb in the altar. It will be saved in the orb chest during crafting and put back after that.
]]

---Scans input box for the first item(s) available for crafting
---@param transposerInput any
---@param side integer
---@param inputToPatterns PatternsLookup
---@return string? outputName
---@return ItemStacksInfo? inputInfo
local function findFirstInput(transposerInput, side, inputToPatterns)
    local stacksInfo = utils.combineStacks(transposerInput, side)
    for name, entry in pairs(stacksInfo) do
        local matchedOutputs = inputToPatterns[name]
        if matchedOutputs ~= nil then
            print(string.format('Found item %s to make %s', name, table.concat(matchedOutputs, ", ")))
            local slot = entry.slots[1]
            if DEBUG then
                print(string.format("Found item %s in slot %d", name, slot))
            end
            return matchedOutputs[1], entry
        end
    end
end

---Transfers items from input container to the altar.
---Tries to batch craft.
---@param transposerInput any the transposer that reads the input container
---@param fromSide integer the side input container is at
---@param toSide integer the side the container connected to altar is at
---@param inputInfo ItemStacksInfo
---@param bloodRequired integer the amount of blood this recipe requires
---@return integer numInput
local function transferInput(transposerInput, fromSide, toSide, inputInfo, bloodRequired)
    local slotInput = inputInfo.slots[1]
    local currentBlood = BLOOD_ALTAR.getCurrentBlood()
    local inputAvail = inputInfo.sizes[1]
    local numInput = math.min(inputAvail, currentBlood // bloodRequired)
    transposerInput.transferItem(fromSide, toSide, numInput, slotInput,
        utils.firstAvailableSlot(transposerInput, toSide))
    if config.debug then
        print(string.format(
            "DEBUG: Transferred %d items. Has %d. Altar blood: %d. Required blood: %d",
            numInput, inputAvail, currentBlood, bloodRequired
        ))
    end
    return numInput
end

---Checks if blood altar has finished its crafting.
---Checks if the output exists, but not its amount.
---@param transposerAltar any
---@param sideAltar integer
---@param nameOutput string
---@return boolean
local function isAltarComplete(transposerAltar, sideAltar, nameOutput)
    local stack = transposerAltar.getStackInSlot(sideAltar, 1)
    if stack ~= nil then
        if stack.label == nameOutput then
            return true
        end
    end
    return false
end

---Transfers items from the altar to output container
---@param transposerAltar any
---@param sideAltar integer
---@param sideOutput integer
---@return integer numOutput
local function transferOutput(transposerAltar, sideAltar, sideOutput)
    local transferred = 0
    local stackInfo = utils.firstStack(transposerAltar, sideAltar)
    if stackInfo then
        transferred = stackInfo.size
        transposerAltar.transferItem(sideAltar, sideOutput, transferred, 1,
            utils.firstAvailableSlot(transposerAltar, sideOutput))
    end
    return transferred
end

---Finds the first blood orb in an inventory, returns its slot number and stack info if found
---@param transposer any
---@param sideInventory integer
---@return integer? slot where is orb is found
---@return StackInfo? orb orb's stack info when it is found
local function getOrbFromInventory(transposer, sideInventory)
    local stackInfo = utils.firstStack(transposer, sideInventory)
    if stackInfo and string.find(stackInfo.name, "^AWWayofTime:.*BloodOrb$") ~= nil then
        return stackInfo.slot, stackInfo
    end
end

---Retrieves any blood orb in the altar and put it in the orb chest.
---Does nothing if there is no orb in the altar
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

---Checks provided patterns info. Exits if anything is wrong.
---@param bloodAltar any
---@param patternsInfo table<string, PatternInfo>
---@param recipeRequirements table<string, BMRecipeRequirement>
---@return boolean result false if something is wrong
---@return string? errMsg about what is wrong
local function checkPatterns(bloodAltar, patternsInfo, recipeRequirements)
    local msg = {}
    for output, _ in pairs(patternsInfo) do
        local requirement = recipeRequirements[string.lower(output)]
        if bloodAltar.getTier() < requirement.tier then
            msg[#msg + 1] = string.format(
                "Pattern of %s needs tier (%d) higher than current one's.",
                output, requirement.tier
            )
        end
    end
    if #msg > 0 then
        return false, table.concat(msg, "\n")
    else
        return true
    end
end

-- =================================
-- == Base class for Altar states ==
-- =================================
---@class AltarState
local AltarState = {}

function AltarState:new()
    local o = {}
    self.__index = self
    o = setmetatable(o, self)
    return o
end

---@return AltarState?
function AltarState:checkSystem() end

---@param inputInfo ItemStacksInfo
function AltarState:enterWithInputInfo(inputInfo) end

---@param name string
---@param amount integer
function AltarState:enterWithOutputInfo(name, amount) end

---@param altarRequirement {blood: integer, tier: integer}
function AltarState:enterWithAltarRequirement(altarRequirement) end

-- ================
-- == Idle State ==
-- ================
---@class IdleState: AltarState
---@field inputToPatterns table<string, string[]>
local IdleState = utils.inheritsFrom(AltarState)

---@param inputToPatterns table<string, string[]>
---@return IdleState
function IdleState:new(inputToPatterns)
    -- Saves patterns into the instance so that
    -- we won't need to scan patterns each time in the main loop.
    -- May choose not to save it to eliminate the needs to
    -- restart to scan for patterns.
    local o = {}
    o = AltarState.new(self) --[[@as IdleState]]
    o.inputToPatterns = inputToPatterns
    return o
end

-- =================
-- == Input State ==
-- =================
---@class InputState: AltarState
---@field inputInfo ItemStacksInfo
---@field outputName string
---@field altarRequirement { blood: integer, tier: integer }
local InputState = utils.inheritsFrom(AltarState)

---@return InputState
function InputState:new()
    local o = {}
    o = AltarState.new(self) --[[@as InputState]]
    return o
end

---@param inputInfo ItemStacksInfo
function InputState:enterWithInputInfo(inputInfo)
    self.inputInfo = inputInfo
end

---@param name string
function InputState:enterWithOutputInfo(name, _)
    self.outputName = name
end

---@param altarRequirement {blood: integer, tier: integer}
function InputState:enterWithAltarRequirement(altarRequirement)
    self.altarRequirement = altarRequirement
end

-- ===========================
-- == Wait for Output State ==
-- ===========================
---@class WaitForOutputState: AltarState
---@field outputLeft integer
---@field outputName string
local WaitForOutputState = utils.inheritsFrom(AltarState)

---@return WaitForOutputState
function WaitForOutputState:new()
    local o = {}
    o = AltarState.new(self) --[[@as WaitForOutputState]]
    return o
end

---@param name string
---@param amount integer
function WaitForOutputState:enterWithOutputInfo(name, amount)
    self.outputLeft = amount
    self.outputName = name
end

-- ==========================
-- == Wait for Blood State ==
-- ==========================
---@class WaitForBloodState: AltarState
---@field inputInfo ItemStacksInfo
---@field outputName string
---@field altarRequirement { blood: integer, tier: integer }
local WaitForBloodState = utils.inheritsFrom(AltarState)

---@return WaitForBloodState
function WaitForBloodState:new()
    local o = {}
    o = AltarState.new(self) --[[@as WaitForBloodState]]
    return o
end

---@param inputInfo ItemStacksInfo
function WaitForBloodState:enterWithInputInfo(inputInfo)
    self.inputInfo = inputInfo
end

---@param name string
function WaitForBloodState:enterWithOutputInfo(name, _)
    self.outputName = name
end

---@param altarRequirement {blood: integer, tier: integer}
function WaitForBloodState:enterWithAltarRequirement(altarRequirement)
    self.altarRequirement = altarRequirement
end

-- ==========================
-- == State Initialization ==
-- ==========================
local MEPatterns, inputToPatterns = utils.getPatternsInfo(ME_INTERFACE)
local STATE_IDLE = IdleState:new(inputToPatterns)
local STATE_INPUT = InputState:new()
local STATE_WAIT_FOR_OUTPUT = WaitForOutputState:new()
local STATE_WAIT_FOR_BLOOD = WaitForBloodState:new()

-- =================================
-- == State Transition Functions ==
-- =================================
---@return AltarState?
function IdleState:checkSystem()
    local outputName, inputInfo = findFirstInput(
        TRANSPOSER_ME, TRANSPOSER_ME_SIDE_INPUT, self.inputToPatterns)
    if outputName and inputInfo then
        local lowerName = string.lower(outputName)
        local requirement = RECIPE_REQUIREMENTS[lowerName]
        local requiredBlood = requirement and requirement.blood
        if requirement then
            if BLOOD_ALTAR.getCurrentBlood() < requiredBlood then
                print(string.format("Waiting for blood in Altar (%d needed).", requiredBlood))
                local nextState = STATE_WAIT_FOR_BLOOD
                nextState:enterWithInputInfo(inputInfo)
                nextState:enterWithOutputInfo(outputName)
                nextState:enterWithAltarRequirement(requirement)
                return nextState
            end
        else
            print(string.format(
                "Blood requirement for %s was not found. Putting it onto Altar regardlessly.",
                outputName
            ))
        end
        local nextState = STATE_INPUT
        nextState:enterWithInputInfo(inputInfo)
        nextState:enterWithOutputInfo(outputName)
        nextState:enterWithAltarRequirement(requirement)
        return nextState
    else
        -- Adds a delay before putting orb back to try to mitigate this issue:
        -- https://github.com/GTNewHorizons/GT-New-Horizons-Modpack/issues/14401
        os.sleep(2)
        putOrbOnAltar(
            TRANSPOSER_ME, TRANSPOSER_ME_SIDE_ORB, TRANSPOSER_ME_SIDE_OUTPUT,
            TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR
        )
    end
end

---@return AltarState?
function InputState:checkSystem()
    saveOrbFromAltar(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_ORB)
    local requiredBlood = self.altarRequirement.blood
    local numInput = transferInput(
        TRANSPOSER_ME, TRANSPOSER_ME_SIDE_INPUT, TRANSPOSER_ME_SIDE_OUTPUT,
        self.inputInfo,
        requiredBlood or BLOOD_ALTAR.getCapacity()
    )
    if numInput == 0 then
        if config.debug then
            print(string.format(
                "DEBUG: Number of items transferred is 0. Back to IDLE state."
            ))
        end
        return STATE_IDLE
    end
    print(string.format("Put %d %s to craft %s (costing %s blood)",
        numInput, self.inputInfo.label, self.outputName,
        requiredBlood and tostring(requiredBlood) or "unknown"))
    local nextState = STATE_WAIT_FOR_OUTPUT
    nextState:enterWithOutputInfo(self.outputName, numInput)
    return nextState
end

---@return AltarState?
function WaitForOutputState:checkSystem()
    if isAltarComplete(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, self.outputName) then
        local transferred = transferOutput(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR,
            TRANSPOSER_ALTAR_SIDE_OUTPUT)
        self.outputLeft = self.outputLeft - transferred
        if transferred > 0 then
            print(string.format("Got %d %s", transferred, self.outputName))
        end
        if self.outputLeft <= 0 then
            return STATE_IDLE
        end
    end
end

---@return AltarState?
function WaitForBloodState:checkSystem()
    if BLOOD_ALTAR.getCurrentBlood() >= self.altarRequirement.blood then
        local nextState = STATE_INPUT
        nextState:enterWithInputInfo(self.inputInfo)
        nextState:enterWithOutputInfo(self.outputName)
        nextState:enterWithAltarRequirement(self.altarRequirement)
        return nextState
    end
end

local function main()
    print(HELLO_MSG)
    print(string.format("Found %d patterns", utils.sizeOfTable(MEPatterns)))
    local result, errMsg = checkPatterns(BLOOD_ALTAR, MEPatterns, RECIPE_REQUIREMENTS)
    if not result then
        io.stderr:write(errMsg)
        os.exit(false)
    end

    local interrupted = false
    event.listen("interrupted", function ()
        interrupted = true
    end)

    ---@type AltarState
    local state = STATE_IDLE
    while not interrupted do
        local next = state:checkSystem()
        if next then
            state = next
        end

        os.sleep(0.5)
    end
end

local function testFindFirstInput()
    local _, inputToPatterns = utils.getPatternsInfo(ME_INTERFACE)
    print(findFirstInput(TRANSPOSER_ME, sides.south, inputToPatterns))
end

local function testTransferInput()
    transferInput(TRANSPOSER_ME, TRANSPOSER_ME_SIDE_INPUT, TRANSPOSER_ME_SIDE_OUTPUT, 1, 100000)
end

local function testIsAltarComplete()
    print(isAltarComplete(TRANSPOSER_ALTAR, sides.east, "Master Blood Orb"))
end

local function testAltarItems()
    print(utils.tableToString(utils.collectStacksInfo(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR)))
end

local function testTransferOutput()
    transferOutput(TRANSPOSER_ALTAR, sides.east, sides.south)
end

local function testSaveOrb()
    saveOrbFromAltar(TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR, TRANSPOSER_ALTAR_SIDE_ORB)
end

local function testPutOrb()
    putOrbOnAltar(
        TRANSPOSER_ME, TRANSPOSER_ME_SIDE_ORB, TRANSPOSER_ME_SIDE_OUTPUT,
        TRANSPOSER_ALTAR, TRANSPOSER_ALTAR_SIDE_ALTAR
    )
end

local function testSavePutOrb()
    putOrbOnAltar(TRANSPOSER_ME, TRANSPOSER_ME_SIDE_ORB, TRANSPOSER_ME_SIDE_OUTPUT, TRANSPOSER_ALTAR,
        TRANSPOSER_ALTAR_SIDE_ALTAR)
end

local function testAltarTier()
    print(string.format("Tier: %d", BLOOD_ALTAR.getTier()))
end

local function testAltarBlood()
    print(string.format("Blood: %d", BLOOD_ALTAR.getCurrentBlood()))
end

local function testAltarCapacity()
    print(string.format("Capacity: %d", BLOOD_ALTAR.getCapacity()))
end

main()
