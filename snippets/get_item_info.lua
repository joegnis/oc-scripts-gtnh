local component = require "component"
local sides = require "sides"

local function firstStack(transposer, sideInventory)
    local stackIterator = transposer.getAllStacks(sideInventory)
    local curStack = stackIterator()
    local curSlot = 1
    while curStack ~= nil do
        if next(curStack) ~= nil then
            return curStack
        end

        curStack = stackIterator()
        curSlot = curSlot + 1
    end
end

-- Change this if needed
local transposer = component.transposer
--local transposer = component.proxy("ID")
local chestSide = sides.top

local args = { ... }
if args[1] == "-h" or args[1] == "--help" then
    print("Prints info about the first item in the chest on top of the (primary) transposer.")
    os.exit(0)
elseif args[1] == "--side" then
    if args[2] then
        chestSide = sides[args[2]]
    else
        print("Specify a side of the transposer.")
        os.exit(1)
    end
end

local function tableToString(obj)
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

local stackInfo = firstStack(transposer, chestSide)
print(tableToString(stackInfo))
