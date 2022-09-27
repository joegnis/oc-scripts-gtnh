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
    Returns the first available slot in the container

    Returns 0 if it is full
]]
function M.firstAvailableSlot(transposer, sideContainer)
    local stackIterator = transposer.getAllStacks(sideContainer)
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

--[[
    Returns the first item in the container

    e.g. It returns {
        name = "Cobblestone",
        slot = 5,
        amount = 24,
        maxAmount = 64
    }

    Returns nil if the container is empty
]]
function M.firstItem(transposer, sideContainer)
    local stackIterator = transposer.getAllStacks(sideContainer)
    local curStack = stackIterator()
    local curSlot = 1
    while curStack ~= nil do
        if next(curStack) ~= nil then
            return { name = curStack.label, slot = curSlot, amount = curStack.size, maxAmount = curStack.maxSize }
        end

        curStack = stackIterator()
        curSlot = curSlot + 1
    end

    return nil
end

--[[
    Collects info about stacks in a container

    e.g. It returns {
        Cobblestone = {
            slots = { 1, 5 },
            amounts = { 28, 64 },
            maxAmount = 64,
        }
    }

    Returns an empty table if the container is empty
]]
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
            local itemName = curStack.label
            local itemAmount = curStack.size

            local entry = stacksInfo[itemName]
            if entry == nil then
                entry = { slots = {}, amounts = {}, maxAmount = curStack.maxSize }
                stacksInfo[itemName] = entry
            end
            local slots = entry.slots
            slots[#slots + 1] = slot
            local amounts = entry.amounts
            amounts[#amounts + 1] = itemAmount
        end

        slot = slot + 1
    end

    return stacksInfo
end

--[[
    Combines incomplete stacks

    e.g. 32,28,4,64 -> 64,64
]]
function M.combineStacks(transposer, stacksInfo, inSide)
    for itemName, entry in pairs(stacksInfo) do
        local slots = entry.slots
        local numStacks = #slots
        local amounts = entry.amounts
        local maxAmount = entry.maxAmount

        local iIncomplete = 1
        while true do
            -- Skips full and empty stacks
            while iIncomplete < numStacks and (amounts[iIncomplete] == maxAmount or amounts[iIncomplete] == 0) do
                iIncomplete = iIncomplete + 1
            end
            if iIncomplete >= numStacks then
                break
            end

            -- Fills up one stack at a time
            local i = iIncomplete + 1
            while i <= numStacks and amounts[iIncomplete] < maxAmount do
                -- Does not break full stacks
                if amounts[i] ~= maxAmount then
                    local incompleteAmt = amounts[iIncomplete]
                    local moveSize = math.min(amounts[i], maxAmount - incompleteAmt)
                    if moveSize > 0 then
                        transposer.transferItem(inSide, inSide, moveSize, slots[i], slots[iIncomplete])
                        amounts[iIncomplete] = incompleteAmt + moveSize
                        amounts[i] = amounts[i] - moveSize
                        print(string.format("Combined %d %s with other %d", moveSize, itemName, incompleteAmt))
                    end
                end
                i = i + 1
            end
            iIncomplete = i - 1 -- i was advanced once when the stack is filled up
        end
    end
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
---@param meInterface any
---@return table<string, {inputs: string[], outputAmount: integer}>
---@return table<string, string[]>
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

return M
