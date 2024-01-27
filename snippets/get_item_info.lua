local component = require "component"
local sides = require "sides"


local args = { ... }
if args[1] == "-h" or args[1] == "--help" then
    print("Prints info about the first item in the chest on top of the (primary) transposer.")
    os.exit(0)
end

-- Change this if needed
local transposer = component.transposer
--local transposer = component.proxy("ID")
-- Change this if needed
local chestSide = sides.top

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

local stackInfo = transposer.getStackInSlot(chestSide, 1)
print(tableToString(stackInfo))
