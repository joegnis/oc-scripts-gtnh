local event = require "event"

package.loaded["config_switcher_fluid_config"] = nil
local config = require "config_switcher_fluid_config"
local utils = require "utils"

local function isItemIgnored(itemTable)
    for _, crit in pairs(config.itemsToIgnore) do
        if string.find(itemTable[crit.field], crit.pattern) then
            return true
        end
    end

    return false
end

local function firstItemNotCircuitInAE(me_interface)
    for _, item in ipairs(me_interface.getItemsInNetwork()) do
        if not isItemIgnored(item) then
            return item
        end
    end
end

local function transferStorageCellOut()
    local cellInfo = utils.firstStack(config.transposerMEChest, config.sideMEChest)
    if not cellInfo then
        return 0
    end

    return config.transposerMEChest.transferItem(config.sideMEChest, config.sideOutputChest, 1, cellInfo.slot)
end

local interrupted = false
event.listen("interrupted", function()
    interrupted = true
end)

local function main()
    local consEmptyCycles = 0
    local isCrafting = false
    while not interrupted do
        local input_hatch_fluid = utils.firstFluid(config.transposerInputHatch, config.sideInputHatch)
        local ae_item = firstItemNotCircuitInAE(config.meInterface)

        if config.debug and (isCrafting or input_hatch_fluid or ae_item) then
            print(string.format(
                "input hatch: %s %d; ae network: %s %d",
                input_hatch_fluid and input_hatch_fluid.label or "N/A",
                input_hatch_fluid and input_hatch_fluid.amount or -1,
                ae_item and ae_item.label or "N/A",
                ae_item and ae_item.size or -1
            ))
        end

        if not input_hatch_fluid and not ae_item then
            consEmptyCycles = consEmptyCycles + 1
        else
            isCrafting = true
            consEmptyCycles = 0
        end

        if isCrafting and consEmptyCycles >= config.numConsecutiveEmptyCycles then
            isCrafting = false
            consEmptyCycles = 0

            local msg = "Crafting should be done. "
            local transferred = transferStorageCellOut()
            if transferred == 0 then
                msg = msg .. "Error: failed to transfer out ME storage cell."
                utils.printErr(msg)
            else
                print(msg)
            end
        end

        os.sleep(0.02)
    end
end

local function printFirstItemInAE()
    for _, item in ipairs(config.meInterface.getItemsInNetwork()) do
        print(utils.tableToString(item))
        return
    end
end

local function printFirstItemInCell()
    local cell = utils.firstStackRaw(config.transposerMEChest, config.sideMEChest)
    if not cell then
        return nil
    end

    print(utils.tableToString(cell.getAvailableItems))
    for _, item_name in ipairs(cell.getAvailableItems) do
    end
end

main()
