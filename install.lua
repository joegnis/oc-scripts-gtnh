local shell = require("shell")
local filesystem = require("filesystem")

local REPO = "https://raw.githubusercontent.com/joegnis/oc-scripts-gtnh"
local DEFAULT_BRANCH = "master"
local SCRIPTS = {
    "blood_altar.lua",
    "bm_alchemist.lua",
    "regulate_size.lua",
    "utils.lua",
    "snippets/get_item_info.lua",
    "snippets/list_components.lua",
    "snippets/list_gt_machines.lua",
    "snippets/show_component_api.lua",
}
local DIRS = {
    "snippets"
}
local CONFIGS = {
    "blood_altar_config.lua",
    "bm_alchemist_config.lua",
    "regulate_size_config.lua",
}

local DESCRIPTION = string.format([[
Usage:
./install [-b|--branch BRANCH] [-u|--update-file FILE]
./install [-b|--branch BRANCH] [-c|--update-config]
./install --help | -h

Options:
  -b --branch BRANCH
    Downloads from a specific branch.
    Default is %s.
  -u --update-file FILE
    Updates a specific file.
  -c --update-config
    Updates all config files.
  -h --help
    Shows this message.

By default, this script always (re)downloads
all source files except for config files.

For config files, by default it downloads all
missing ones but does not download existing ones.
To force download a config file, use -u option.
Before it updates a config file,
it backs up existing one before proceeding.
]], DEFAULT_BRANCH)

---@param filename string
---@return boolean
local function exists(filename)
    return filesystem.exists(shell.getWorkingDirectory() .. "/" .. filename)
end

---@param file string
---@param repo string
---@param branch string
local function downloadFile(file, repo, branch)
    shell.execute(string.format(
        "wget -f %s/%s/%s ./%s",
        repo, branch, file, file
    ))
end

---@param config string
---@param repo string
---@param branch string
local function downloadConfig(config, repo, branch)
    local backup = config .. ".bak"
    if exists(config) then
        if exists(backup) then
            shell.execute("rm " .. backup)
        end
        shell.execute(string.format("mv %s %s", config, backup))
        print(string.format("Backed up %s as %s", config, backup))
    end
    downloadFile(config, repo, branch)
end

local function main(args)
    local numArgs = 1
    local curArg = args[numArgs]
    if curArg == "--help" or curArg == "-h" then
        print(DESCRIPTION)
        return true
    end

    local branch = DEFAULT_BRANCH
    if curArg == "--branch" or curArg == "-b" then
        branch = args[numArgs + 1]
        numArgs = numArgs + 2
        if string.find(branch, "^-") then
            io.stderr:write("invalid branch name: " .. branch)
            return false
        end
    end

    local option = args[numArgs]
    if option == "-c" or option == "--update-config" then
        for _, config in ipairs(CONFIGS) do
            downloadConfig(config, REPO, branch)
        end
    elseif option == "-u" or option == "--update-file" then
        local fileArg = args[numArgs + 1]
        numArgs = numArgs + 2
        for _, config in ipairs(CONFIGS) do
            if fileArg == config then
                downloadConfig(fileArg, REPO, branch)
                return true
            end
        end
        downloadFile(fileArg, REPO, branch)
    elseif option == nil then
        for _, dir in ipairs(DIRS) do
            shell.execute(string.format("mkdir %s", dir))
        end

        for _, script in ipairs(SCRIPTS) do
            downloadFile(script, REPO, branch)
        end

        for _, config in ipairs(CONFIGS) do
            if not exists(config) then
                downloadFile(config, REPO, branch)
            else
                print("Skipped existing config file: " .. config)
            end
        end
    else
        error("unknown argument: " .. option)
    end
    return true
end

main({ ... })
