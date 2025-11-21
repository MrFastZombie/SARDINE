local sardineLib = require("__SARDINE__/sardineLib")
local gui = require("__SARDINE__/gui")
local sardineTick = require("__SARDINE__/tick")

script.on_init(function ()
    sardineLib.initData()
end)

script.on_configuration_changed(function ()
    sardineLib.initData()
end)

script.on_event(defines.events.on_player_driving_changed_state, function(event)
    local player = game.get_player(event.player_index)
        if not player then return end
    local vehicle = event.entity
        if not vehicle then return end

    if vehicle.name == "MFZ-sardine" and #vehicle.train.passengers > 0 and sardineLib.checkTickState(vehicle) == false then
        log("SARDINE: Player entered the S.A.R.D.I.N.E.")
        sardineLib.startTicking(vehicle)
        gui.createGui(player)
        --Add sardne to ticking entity list
    elseif vehicle.name == "MFZ-sardine" and #vehicle.train.passengers == 0 then
        log("SARDINE: Player left the S.A.R.D.I.N.E.")
        sardineLib.stopTicking(vehicle)
        gui.destroy(player)
    end
end)

script.on_nth_tick(1, function()
    --log("SARDINE: 60 ticks have passed")
    sardineTick.tickSardines()
end)

script.on_nth_tick(tonumber(settings.startup["sardine-trace-tick-time"].value), function() --This tick function handles scanning lines of ghost track, splitting it into batches. 
    if storage.data["sardineScanQueue"] then
        for index, entry in pairs(storage.data["sardineScanQueue"]) do
            if entry.complete==false then
                sardineLib.processGhostLine(entry.sardine)
            end
        end
    end
end)

script.on_event(defines.events.on_gui_click, function(event)
    gui.onClick(event)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
    gui.onCheckedStateChange(event)
end)