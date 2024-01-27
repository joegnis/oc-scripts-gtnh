local component = require "component"
local os = require "os"


local args = { ... }

if not args[1] or args[1] == "-h" or args[1] == "--help" then
    print("Specify a component to list its api.")
    print("You can list components by running list_components.lua.")
    os.exit(0)
end

for k, v in pairs(component[args[1]]) do
    print(string.format("%s\n%s\n", k, v))
end
