local component = require "component"

local components = component.list()
for addr, comp in pairs(components) do
    print(string.format("%-15s%-32s...", comp, addr))
end
