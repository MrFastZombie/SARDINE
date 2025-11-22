local sardineTick = {}

local gui = require("__SARDINE__/gui")
local sardineLib = require("__SARDINE__/sardineLib")
local dataManager = require("__SARDINE__/dataManager")

---Ticks active sardines, allowing them to perform their duties if needed. Generally, they should only tick when there is a driver or while performing a job.
function sardineTick.tickSardines()
    --if #storage.data["tickingSardines"] == 0 then return end
    for index, value in pairs(storage.data["tickingSardines"]) do
        local player = value.train.carriages[1].get_driver()
        if player ~= nil then
            local playerSelected = player.selected
            if playerSelected ~= nil then
                sardineLib.getPossibleTraversalPieces(playerSelected, value.draw_data.orientation, value)
    
                local msgOri
                if playerSelected.bounding_box.orientation ~= nil then
                    msgOri = playerSelected.bounding_box.orientation else msgOri = playerSelected.orientation
                end
    
                if playerSelected.name == "entity-ghost" then debugFlyMsg("Entity ori: "..msgOri.." True Orientation: "..getRelativeOrientation(playerSelected, value).. " Train orientation: "..snapOrientation(value.draw_data.orientation), value.train.carriages[1].position) end
                if playerSelected.name == "entity-ghost" then debugFlyMsg(playerSelected.ghost_name.. " "..playerSelected.position.x.." "..playerSelected.position.y, playerSelected.position) end   
            end
        end

        local line = {}
        local oris = {}
        if storage.data["sardineScanQueue"] then
            if storage.data["sardineScanQueue"][value.train.id] then
                local entry = storage.data["sardineScanQueue"][value.train.id]
                if entry.complete == true then
                    line = entry.rails
                    oris = entry.orientations
                end
            end
        end

        if storage.data["sardineLastTickRail"] == nil then sardineLib.initData() end
        local lastRail = storage.data["sardineLastTickRail"][value.train.id]
        if lastRail == nil then lastRail = "" end
        
        if value.train.front_end.rail ~= lastRail then
            storage.data["sardineLastTickRail"][value.train.id] = value.train.front_end.rail
            local ghost =  sardineLib.getPossibleTraversalPieces(value.train.front_end.rail, value.draw_data.orientation, value)[1]
    
            if ghost ~= nil then
                --local line, oris = sardineLib.processGhostLine(value, ghost)
                sardineLib.enqueueTrace(value, ghost)
                if player ~= nil then gui.setStatusLabel(player, "scan") end
            else
                dataManager.storeJobData(value, {}, {})
                sardineLib.deenqueueTrace(value)
                if player ~= nil then
                    gui.updateCosts(player, {})
                    gui.setStatusLabel(player, "idle")
                    gui.setButtonState(player, false)
                end
            end
        else
            if #line >= 1 then
                table.insert(line, 1, value.train.front_end.rail) --I don't remember why this was necessary but it appears to work fine with this.
                --sardineLib.stopTicking(value)
                --sardineLib.getCost(line)
                sardineLib.deenqueueTrace(value)
                --sardineLib.startJob(value, line, oris)
                --doJob(value, line)
                
                if player ~= nil then
                    dataManager.storeJobData(value, line, oris, player)
                    dataManager.initInventory(value)
                    gui.updateCosts(player, sardineLib.getCost(line))
                    gui.setButtonState(player, true) --Thisn will also handle the status label.
                end
            end
        end
    end

    if storage.data["sardinesOnJob"] == nil then sardineLib.initData() end
    for index, sardine in pairs(storage.data["sardinesOnJob"]) do
        local result = sardineLib.attemptRailPlacement(sardine)
        if sardine.train.front_end.move_natural() ~= false then
            sardine.train.manual_mode = true
            sardine.train.speed = sardine.train.max_forward_speed*0.75
        end

        local onWorkRail = railIsWorkEntity(sardine.train.front_end.rail, sardine)

        if onWorkRail == false or sardine.train.front_end.rail == storage.data["sardineWorkTiles"][sardine.train.id][#storage.data["sardineWorkTiles"][sardine.train.id]] then
            sardineLib.stopJob(sardine)
            sardine.train.speed = 0
            --if sardine.get_driver ~= nil then sardineLib.setState(sardine) end
        end
    end
end

return sardineTick