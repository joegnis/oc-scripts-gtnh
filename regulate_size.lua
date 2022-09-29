local component = require("component")
local config = require("regulate_size_config")

local utils = require("utils")

local REGULATORS = config.regulators


--[[
    Moves items in multiples of the specified size

    After combining stacks, we no longer worry about leaving items in scattered stacks
]]
---@param transposer any
---@param stacksInfo table<string, ItemStacksInfo>
---@param size integer
---@param inSide integer
---@param outSide integer
local function move(transposer, stacksInfo, size, inSide, outSide)
    for itemName, entry in pairs(stacksInfo) do
        if utils.firstAvailableSlot(transposer, outSide) == 0 then
            print("Output chest is full. Stopped moving.")
            break
        end

        local slots = entry.slots
        local numSlots = #slots
        local sizes = entry.sizes
        local i = 1
        while i <= numSlots do
            local slot = slots[i]
            local stackSize = sizes[i]
            if stackSize >= size then
                local sizeToMove = (stackSize // size) * size
                local outSlot = utils.firstAvailableSlot(transposer, outSide)
                if outSlot == 0 then goto continue end
                transposer.transferItem(inSide, outSide, sizeToMove, slot, outSlot)
                print(string.format("Moved %d %s", sizeToMove, itemName))
                stackSize = stackSize - sizeToMove
            end

            -- May have an incomplete stack
            if i + 1 <= numSlots then
                local nextSlot = slots[i + 1]
                if stackSize + sizes[i + 1] >= size then
                    local outSlot = utils.firstAvailableSlot(transposer, outSide)
                    if outSlot == 0 then goto continue end
                    transposer.transferItem(inSide, outSide, stackSize, slot, outSlot)
                    transposer.transferItem(inSide, outSide, size - stackSize, nextSlot, outSlot)
                    print(string.format("Moved %d %s", stackSize, itemName))
                    sizes[i] = 0
                    sizes[i + 1] = sizes[i + 1] - (size - stackSize)
                else
                    -- Merges leftover
                    transposer.transferItem(inSide, inSide, stackSize, slot, nextSlot)
                    print(string.format("Combined %d %s with other %d", stackSize, itemName, sizes[i + 1]))
                    sizes[i] = 0
                    sizes[i + 1] = sizes[i + 1] + stackSize
                end
            end

            i = i + 1
        end

        ::continue::
    end
end

local function regulateSize(transposer, inSide, outSide, size)
    local outSlot = utils.firstAvailableSlot(transposer, outSide)
    if outSlot == 0 then
        local sleepDuration = 5
        print(string.format("Output chest is full. Sleeping for %d seconds", sleepDuration))
        os.sleep(sleepDuration)
        return
    end

    utils.combineStacks(transposer, utils.collectStacksInfo(transposer, inSide), inSide)
    move(transposer, utils.collectStacksInfo(transposer, inSide), size, inSide, outSide)
    utils.combineStacks(transposer, utils.collectStacksInfo(transposer, outSide), outSide)
end

local function main()
    while true do
        for _, regulator in ipairs(REGULATORS) do
            local transposer = component.proxy(regulator.transposer)
            for inSide, size in pairs(regulator.sideToSizes) do
                regulateSize(transposer, inSide, regulator.outSide, size)
            end
        end
        os.sleep(1)
    end
end

local function testRegulateSize()
    local transposer = component.proxy("3b059f55-3d7d-4c85-ac1d-7a561234d49c")
    regulateSize(transposer, 2, 3, 7)
end

local function testMove()
    local transposer = component.proxy("3b059f55-3d7d-4c85-ac1d-7a561234d49c")
    local stacksInfo = utils.collectStacksInfo(transposer, 2)
    move(transposer, stacksInfo, 7, 2, 3)
end

local function testCombineStacks()
    local transposer = component.proxy("3b059f55-3d7d-4c85-ac1d-7a561234d49c")
    local stacksInfo = utils.collectStacksInfo(transposer, 2)
    utils.combineStacks(transposer, stacksInfo, 2)
end

main()
