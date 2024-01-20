local M = {}

function M.sizeOfTable(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function M.tableToString(obj)
    local function toString(o)
        if type(o) == 'table' then
            local s = '{ '
            for k, v in pairs(o) do
                if type(k) ~= 'number' then
                    k = '"' .. k .. '"'
                end
                s = s .. '[' .. k .. '] = ' .. toString(v) .. ','
            end
            return s .. '} '
        else
            return tostring(o)
        end
    end

    return toString(obj)
end

-- http://lua-users.org/wiki/CopyTable
function M.shallowCopy(orig)
    local origType = type(orig)
    local copy
    if origType == 'table' then
        copy = {}
        for origKey, origValue in pairs(orig) do
            copy[origKey] = origValue
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--[[
    Creates a child class table inherited from baseClass.
]]
function M.inheritsFrom(baseClass)
    if not baseClass then
        error("baseClass should not be nil", 2)
    end
    local childClass = {}
    baseClass.__index = baseClass
    childClass = setmetatable(childClass, baseClass)
    return childClass
end

--[[
    Tests if a value is an instance of a class.

    Checks inheritance. Inheritance should be made by the inheritsFrom
    method above.
]]
---@param value any
---@param klass any
---@return boolean
function M.isInstance(value, klass)
    if type(value) == "table" then
        local curClass = getmetatable(value)
        while curClass do
            if curClass == klass then
                return true
            else
                curClass = getmetatable(curClass)
            end
        end
    end
    return false
end

--[[
    Returns the first available slot in the inventory

    Returns 0 if it is full
]]
function M.firstAvailableSlot(transposer, sideInventory)
    local stackIterator = transposer.getAllStacks(sideInventory)
    local curStack = stackIterator()
    local curSlot = 1
    while curStack ~= nil do
        if next(curStack) == nil then
            return curSlot
        end
        curStack = stackIterator()
        curSlot = curSlot + 1
    end
    return 0
end

---@alias StackInfo { label: string, name: string, slot: integer, size: integer, maxSize: integer }
--[[
    Returns the first stack in the inventory

    e.g. It returns {
        name = "minecraft:cobblestone",
        label = "Cobblestone",
        slot = 5,
        size = 24,
        maxSize = 64
    }

    Returns nil if the inventory is empty
]]
---@param transposer any
---@param sideInventory integer
---@return StackInfo?
function M.firstStack(transposer, sideInventory)
    local stackIterator = transposer.getAllStacks(sideInventory)
    local curStack = stackIterator()
    local curSlot = 1
    while curStack ~= nil do
        if next(curStack) ~= nil then
            return {
                name = curStack.name,
                label = curStack.label,
                slot = curSlot,
                size = curStack.size,
                maxSize = curStack.maxSize,
            }
        end

        curStack = stackIterator()
        curSlot = curSlot + 1
    end
end

---@alias ItemStacksInfo { name: string, label: string, slots: integer[], sizes: integer[], maxSize: integer}

--[[
    Collects info about stacks in an inventory

    e.g. It returns {
        Cobblestone = {
            name = "minecraft:cobblestone"
            label = "Cobblestone",
            slots = { 1, 5 },
            sizes = { 28, 64 },
            maxSize = 64,
        }
    }

    Returns an empty table if the inventory is empty
]]
---@param transposer any
---@param side integer
---@return table<string, ItemStacksInfo>
function M.collectStacksInfo(transposer, side)
    local stackIterator = transposer.getAllStacks(side)
    local stacksInfo = {}
    local slot = 1
    while true do
        local curStack = stackIterator()
        if curStack == nil then
            break
        end
        if next(curStack) ~= nil then
            ---@type string
            local itemLabel = curStack.label
            ---@type string
            local itemName = curStack.name
            ---@type integer
            local stackSize = curStack.size

            local entry = stacksInfo[itemLabel]
            if entry == nil then
                entry = { name = itemName, label = itemLabel, slots = {}, sizes = {}, maxSize = curStack.maxSize }
                stacksInfo[itemLabel] = entry
            end
            table.insert(entry.slots, slot)
            table.insert(entry.sizes, stackSize)
        end

        slot = slot + 1
    end

    return stacksInfo
end

--[[
    Combines incomplete stacks but does not sort them

    e.g. 32,28,4,64 -> 64,64
]]
---@param transposer any
---@param side integer
---@param verbose boolean?
---@return table<string, ItemStacksInfo> # stacks info after combination
function M.combineStacks(transposer, side, verbose)
    local stacksInfo = M.collectStacksInfo(transposer, side)
    for itemName, entry in pairs(stacksInfo) do
        local slots = entry.slots
        local numStacks = #slots
        local sizes = entry.sizes
        local maxSize = entry.maxSize

        local iIncomplete = 1
        while true do
            -- Skips full and empty stacks
            while iIncomplete < numStacks and (sizes[iIncomplete] == maxSize or sizes[iIncomplete] == 0) do
                iIncomplete = iIncomplete + 1
            end
            if iIncomplete >= numStacks then
                break
            end

            -- Fills up one stack at a time
            -- Finds a stack after the incomplete stack to combine with
            local iSrc = iIncomplete + 1
            while iSrc <= numStacks and sizes[iIncomplete] < maxSize do
                -- Does not break full stacks
                if sizes[iSrc] ~= maxSize then
                    local incompleteAmt = sizes[iIncomplete]
                    local moveSize = math.min(sizes[iSrc], maxSize - incompleteAmt)
                    if moveSize > 0 then
                        transposer.transferItem(side, side, moveSize, slots[iSrc], slots[iIncomplete])
                        sizes[iIncomplete] = incompleteAmt + moveSize
                        sizes[iSrc] = sizes[iSrc] - moveSize
                        if verbose then
                            print(string.format("Combined %d %s with other %d",
                                moveSize, itemName, incompleteAmt))
                        end
                    end
                end
                iSrc = iSrc + 1
            end
            iIncomplete = iSrc - 1 -- i was advanced one more time when the stack is filled up
        end
    end

    -- Rescans to remove stacks with size 0
    return M.collectStacksInfo(transposer, side)
end

--[[
    Gets patterns info from an ME interface with an extra table for
    faster pattern lookup for an output item from an input item

    e.g. returns
        {
            ["Reinforced Slate"] = {
                inputs = { ["Blank Slate"] = 1 },
                outputAmount = 1
            }
        },
        {
            ["Blank Slate"] = { "Reinforced Slate" }
        }
]]
---@alias PatternInfo {inputs: string[], outputAmount: integer}
---@alias PatternsLookup table<string, string[]> reverse lookup table of patterns
---@param meInterface any
---@return table<string, PatternInfo>
---@return PatternsLookup
function M.getPatternsInfo(meInterface)
    local patternsInfo = {}
    for i = 1, 36 do -- 36 is the max number of patterns
        local pattern = meInterface.getInterfacePattern(i)
        if pattern ~= nil then
            local inputs = pattern.inputs
            local outputs = pattern.outputs
            local output = outputs[1]
            if output ~= nil then
                local patternInputs = {}
                for _, t in ipairs(inputs) do
                    local inputName = t.name
                    if inputName ~= nil then
                        -- Breaks when an input is nil, so
                        -- AE patterns should not have empty slots
                        -- in between
                        patternInputs[inputName] = t.count
                    else
                        break
                    end
                end

                patternsInfo[output.name] = {
                    inputs = patternInputs,
                    outputAmount = output.count
                }
            else
                print("Invalid pattern: no outputs")
            end
        end
    end

    local inputToPatterns = {}
    for output, entry in pairs(patternsInfo) do
        for input, _ in pairs(entry.inputs) do
            if inputToPatterns[input] == nil then
                inputToPatterns[input] = {}
            end
            local numPatterns = #inputToPatterns[input]
            inputToPatterns[input][numPatterns + 1] = output
        end
    end

    return patternsInfo, inputToPatterns
end

local function testFirstAvailableSlot()
    local component = require "component"
    local transposer = component.proxy("3b059f55-3d7d-4c85-ac1d-7a561234d49c")
    local slot = M.firstAvailableSlot(transposer, 2)
    print("First available slot is " .. slot)
end

local function testGetPatternsInfo()
    local component = require "component"
    local patterns, inputToPatterns = M.getPatternsInfo(component.me_interface)
    print("Patterns:")
    print(M.tableToString(patterns))
    print("Input to Patterns:")
    print(M.tableToString(inputToPatterns))
end

local function testCombineStacks()
    local component = require "component"
    local sides = require "sides"
    local transposer = component.transposer
    local side = sides.top
    print(M.tableToString(
        M.combineStacks(transposer, side, true)
    ))
end

return M
