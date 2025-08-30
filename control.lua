local sardineLib = require("__SARDINE__/sardineLib")

script.on_init(function ()
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
        --Add sardne to ticking entity list
    elseif vehicle.name == "MFZ-sardine" and #vehicle.train.passengers == 0 then
        log("SARDINE: Player left the S.A.R.D.I.N.E.")
        sardineLib.stopTicking(vehicle)
    end
end)

script.on_nth_tick(60, function()
    --log("SARDINE: 60 ticks have passed")
    sardineLib.tickSardines()
end)