local component = require "component"
local os = require "os"

local DESCRIPTION = [[
Usage:
./show_component_api.lua --name COMPONENT_NAME
./show_component_api.lua --id COMPONENT_ID
./show_component_api.lua --gt KEYWORD
    Matches as long as keyword is
    contained in the machine name
./show_component_api.lua --help | -h

Specify a component to list its api by its
name or id.
]]

local function print_api(comp)
    for k, v in pairs(comp) do
        print(string.format("%s\n%s\n", k, v))
    end
end


local args = { ... }

if not args[1] or args[1] == "-h" or args[1] == "--help" then
    print(DESCRIPTION)
    os.exit(0)
elseif args[1] == "--id" then
    if args[2] then
        print_api(component.proxy(args[2]))
    else
        print("Specify a component id.")
        os.exit(1)
    end
elseif args[1] == "--name" then
    if args[2] then
        print_api(component[args[2]])
    else
        print("Specify a component name.")
        os.exit(1)
    end
elseif args[1] == "--gt" then
    if args[2] then
        local target = args[2]
        local found = false
        for addr, comp in pairs(component.list()) do
            if comp == "gt_machine" then
                local machine = component.proxy(addr)
                local name = machine.getName()
                print(name)
                if string.find(name, target) then
                    found = true
                    print_api(machine)
                    break
                end
            end
        end
        if not found then
            print("Machine not found.")
            os.exit(2)
        end
    else
        print("Specify a GT machine name. List them by list_gt_machines.lua.")
        os.exit(1)
    end
else
    print("Unknown option.")
        os.exit(1)
end
