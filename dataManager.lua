local dataManager = {}

function dataManager.initData()
    storage.data = storage.data or {}
    storage.data["sardineInventory"] = storage.data["sardineInventory"] or {}
    storage.data["sardinePoleCache"] = storage.data["sardinePoleCache"] or {}
    storage.data["sardinePlayerSettings"] = storage.data["sardinePlayerSettings"] or {}
    storage.data["sardinePotentialWork"] = storage.data["sardinePotentialWork"] or {}
---Gets the potential job data for a SARDINE.
---@param sardine LuaEntity
---@return LuaEntity[]|nil, number[]|nil, LuaPlayer|nil
function dataManager.getJobData(sardine)
    if storage.data["sardinePotentialWork"] == nil then return nil, nil end
    if storage.data["sardinePotentialWork"][sardine.train.id] == nil then return nil, nil end
    return storage.data["sardinePotentialWork"][sardine.train.id]["entityList"], storage.data["sardinePotentialWork"][sardine.train.id]["orientationList"], storage.data["sardinePotentialWork"][sardine.train.id]["player"]
end

--Stores the current potential job for a SARDINE.
---@param sardine LuaEntity
---@param entityList (LuaEntity)[]
---@param orientationList (number)[]
function dataManager.storeJobData(sardine, entityList, orientationList, player)
    if storage.data["sardinePotentialWork"] == nil then dataManager.initData() end
    if #orientationList < 1 or #entityList < 1 then
        table.remove(storage.data["sardinePotentialWork"], sardine.train.id)
        return
    end
    storage.data["sardinePotentialWork"][sardine.train.id] = {entityList=entityList, orientationList=orientationList, player=player}
end

---Stores a setting value based on player and key.
---@param player LuaPlayer
---@param key string
---@param value any
---@return boolean true Always returns true as of now. 
function dataManager.savePlayerSetting(player, key, value)
    if not storage.data["sardinePlayerSettings"] then dataManager.initData() end
    storage.data["sardinePlayerSettings"][player.index] = storage.data["sardinePlayerSettings"][player.index] or {}
    storage.data["sardinePlayerSettings"][player.index][key] = value
    return true
end

---Gets a player's setting from a key
---@param player LuaPlayer
---@param key string
---@return any
function dataManager.getPlayerSetting(player, key)
    if not storage.data["sardinePlayerSettings"] then dataManager.initData() end
    if not storage.data["sardinePlayerSettings"][player.index] then return false end
    if not storage.data["sardinePlayerSettings"][player.index][key] then return false end
    return storage.data["sardinePlayerSettings"][player.index][key]
end

function dataManager.cachePowerPoles()
    if not storage.data["sardinePoleCache"] then dataManager.initData() end
    for key, pole in pairs(prototypes.get_entity_filtered({{filter="type", type="electric-pole"}})) do
        if not pole.hidden then
            local wireDistance = pole.get_max_wire_distance() --Can be affected by quality, but we'll probably treat them all as the base quality.
            local maxCircuitWireDistance = pole.get_max_circuit_wire_distance()
            local supplyArea = pole.get_supply_area_distance()
            storage.data["sardinePoleCache"][key] = {wireDistance = wireDistance, circuitWireDistance = maxCircuitWireDistance, supplyArea = supplyArea, width=pole.tile_width, height=pole.tile_height, prototype=pole}
        end
    end
end

---Clears the inventory tracking cache for a SARDINE when tracking is no longer needed.
---@param sardine LuaEntity
function dataManager.clearInventoryCache(sardine)
    if not storage.data["sardineInventory"] then dataManager.initData() end
    if storage.data["sardineInventory"][sardine.train.id] then
        storage.data["sardineInventory"][sardine.train.id] = nil
    end
end --end of clearInventoryCache()

---Collects the current inventory of a SARDINE. Should be used when scanning a new job.
---@param sardine LuaEntity
function dataManager.initInventory(sardine)
    local inventoryList = {}
    if not storage.data["sardineInventory"] then dataManager.initData() end

    ---@param ItemStack LuaItemStack
    function countItem(ItemStack)
        if #inventoryList == 0 then
            table.insert(inventoryList, {name = ItemStack.name, count = ItemStack.count, prototypes = ItemStack.prototype})
            return
        else
            for index, item in ipairs(inventoryList) do
                if item.name == ItemStack.name then
                    item.count = ItemStack.count + item.count
                    return
                elseif index == #inventoryList then
                    table.insert(inventoryList, {name = ItemStack.name, count = ItemStack.count, prototypes = ItemStack.prototype})
                    return
                end
            end
        end
    end

    local wagons = sardine.train.cargo_wagons or {}

    if wagons == {} then
        return
    end

    for index, wagon in ipairs(wagons) do
        local inventory = wagon.get_inventory(defines.inventory.cargo_wagon)
        if inventory then
            local i = 1
            while i <= #inventory do
                local stack = inventory[i]
                if stack.valid_for_read and stack.valid then
                    countItem(stack)
                end
                i = i + 1
            end
        end
    end

    storage.data["sardineInventory"][sardine.train.id] = inventoryList
    dataManager.useItem(sardine, "copper-plate", 69) --TODO: Remove this debug function call.
    log("INVENTORY!!!!!!")
end --End of initInventory()

---Inserts an item into a Sardine.
---@param sardine LuaEntity
---@param itemStack LuaItemStack
---@return uint32 inserted The number of items inserted.
function dataManager.insertItem(sardine, itemStack)
    --TODO: Test this function.
    if not storage.data["sardineInventory"] then dataManager.initData() end
    local wagons = sardine.train.cargo_wagons or {}
    if #wagons >= 1 then
        for index, wagon in ipairs(wagons) do
            if wagon.can_insert(itemStack) then
                local inserted = wagon.insert(itemStack)
                return inserted
            elseif index == #wagons then
                return 0
            end
        end
    end
    return 0
end --End of insertItem()

---Uses an item that a sardine might have. This will remove the item from its inventory and reflect the change in its inventory cache.
---comment
---@param sardine LuaEntity
---@param itemName string
function dataManager.useItem(sardine, itemName, itemCount)
    if not storage.data["sardineInventory"] then dataManager.initData() end
    local removed = false
    local removeCount = 0
    local removedAmount = itemCount --Basicaly just so the item count can be used later to update the cache.
    itemCount = itemCount or 1
    local wagons = sardine.train.cargo_wagons or {}

    function hasEnoughItems() --We should check if we have enough to begin with, before removing any items.
        local foundAmount = 0
        for index, wagon in ipairs(wagons) do --Search each cargo wagon
            local countedAmount = wagon.get_item_count({name=itemName}) or 0
            foundAmount = foundAmount + countedAmount --Tally the total found
        end

        if foundAmount >= itemCount then --If there are more/equal what we need
            return true
        else
            return false
        end
    end

    if #wagons >= 1 and hasEnoughItems() then
        for index, wagon in ipairs(wagons) do
            removeCount = wagon.remove_item({name=itemName, count=itemCount})
            if removeCount == itemCount then
                removed = true
                break
            else
                itemCount = itemCount - removeCount
            end

            if itemCount == 0 then
                removed = true
                break
            end
        end
    end

    if removed and storage.data["sardineInventory"][sardine.train.id] then --We won't init the inventory as we may want to use this function when we're not tracking the SARDINE's inventory.
        for index, item in ipairs(storage.data["sardineInventory"][sardine.train.id]) do
            if item.name == itemName then
                item.count = item.count - removedAmount
                if item.count < 0 then item.count = 0 end --Obviously this would be wrong, but this I'd rather avoid any bugs with negative numbers.
                break
            end
        end
    end

    return removed
end --End of useItem()

return dataManager