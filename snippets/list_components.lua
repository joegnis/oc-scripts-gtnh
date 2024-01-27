local component = require "component"

local args = { ... }
if args[1] == "-h" or args[1] == "--help" then
    print("Lists all components in the system")
    os.exit(0)
end

local components = component.list()
for addr, comp in pairs(components) do
    print(string.format("%-15s%s", comp, addr))
end
