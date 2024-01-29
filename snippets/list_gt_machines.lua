local component = require "component"

local args = { ... }
if args[1] == "-h" or args[1] == "--help" then
    print("Lists all GT machines in the system")
    os.exit(0)
end

local components = component.list()
for addr, comp in pairs(components) do
    if comp == "gt_machine" then
        local machine = component.proxy(addr)
        print(string.format("%-20s%s", machine.getName(), addr))
    end
end
