local sardineLib = {}

---Initialize the mod's data.
function sardineLib.initData()
    storage.data = storage.data or {}
    if not storage.data["tickingSardines"] then storage.data["tickingSardines"] = {} end
end

---Add a sardine to the list of vehicles that should be running their on tick events
---@param sardine LuaEntity
function sardineLib.startTicking(sardine)
    if sardineLib.checkTickState(sardine) then return end
    storage.data["tickingSardines"][sardine.train.id] = sardine
end

---Remove a sardine from the ticking list
---@param sardine LuaEntity
function sardineLib.stopTicking(sardine) --Stop ticking when: player is found to not be in vehicle, when a vehicle has been given a task
    if sardineLib.checkTickState(sardine) == false then return end
    table.remove(storage.data["tickingSardines"],sardine.train.id)
end

---Check if a sardine is set to tick.
---@param sardine LuaEntity
---@return boolean
function sardineLib.checkTickState(sardine)
    if storage.data["tickingSardines"][sardine.train.id] then return true
    else return false
    end
end

---Get a S.A.R.D.I.N.E by ID
---@param id any
function sardineLib.getSardine(id)
end

---aaaa
---@param sardine LuaEntity
function getLastRail(sardine)
    local rail = sardine.train.front_end.rail
    local player = sardine.train.carriages[1].get_driver()
    local limit = 30
    local testRail = rail
    local last = rail
    local i = 1

    if player == nil then return end
    while testRail and i < limit do
        i = i+1
        local result = last.get_connected_rail{rail_direction=defines.rail_direction.front, rail_connection_direction=defines.rail_connection_direction.straight}
        if result == nil then return end
        player.create_local_flying_text{text="A", position=result.position}
        last = result
        if result.type == "entity-ghost" then
            player.create_local_flying_text{text="Found a ghost!", position=result.position}
        end
    end
    return last
end

--East: +X West: -X North +Y? South: -Y?
--Only allow it to start on a straight-rail and elevated-straight-rail (use ghost-name or ghost-type property), for technical reasons.
--Consider half-diagonal-rail?
---Scans the track in front of the sardine to check if it's a ghost.
---@param sardine LuaEntity
function sardineLib.scanTrack(sardine)
    --if sardine.train.front_end.move_natural then return nil end
    local location = sardine.train.front_end.location
    local direction = sardine.train.front_end.rail.direction
    local entities =  sardine.surface.find_entities_filtered{position = location.position, radius = 3, type="entity-ghost"}
    --local stuff = sardine.surface.get_closest(location.position, entities)


    for i, v in pairs(entities) do
        sardine.train.carriages[1].get_driver().create_local_flying_text{text=v.ghost_name, position=v.position}
    end

    if(#entities > 0) then
        local rails = sardine.train.get_rails()
        sardine.train.carriages[1].get_driver().create_local_flying_text{text="draw rot: "..sardine.draw_data.orientation.." RD: "..entities[1].direction.." Rails: "..#rails, position=sardine.position}
    end

    if location.rail_layer == 0 then -- Normal rail
        --TODO: Add check that ghost rail faces same direction
        for i, v in pairs(entities) do
            if v.ghost_type == "elevated-straight-rail" then
                table.remove(entities, i)
            end
        end
    end

    if location.rail_layer == 1 then -- Elevated rail
        
    end
    return nil
end

---Use a rail and train to find the ghost
---@param sardine LuaEntity
function getNextGhost(sardine)
    local orientation = sardine.draw_data.orientation
    local location = sardine.train.front_end.location
    local railUnderTrain = sardine.train.front_end.rail
    local offset = {x=0, y=0}
    local radius = 1
    if orientation == 0 then --Facing NORTH
        offset.y = -1
    end
    if orientation > 0 and orientation < 0.125 then -- Facing Hal-diagonal towards north from east
        offset.y = -2
        offset.x = 1
        radius = 2
    end
    if orientation == 0.125 then --Facing NORTH EAST
        offset.y = -1
        offset.x = 1
    end
    if orientation > 0.125 and orientation < 0.25 then -- Facing Hal-diagonal towards east  from north
        offset.y = -1
        offset.x = 2
        radius = 2
    end
    if orientation == 0.25 then --Facing EAST
        offset.x = 1
    end
    if orientation > 0.25 and orientation < 0.375 then -- Facing Hal-diagonal towards east from south
        offset.y = 1
        offset.x = 2
        radius = 2
    end
    if orientation == 0.375 then --Facing SOUTH EAST
        offset.y = 1
        offset.x = 1
    end
    if orientation > 0.375 and orientation < 0.5 then -- Facing Hal-diagonal towards South from East
        offset.y = 1
        offset.x = 2
        radius = 2
    end
    if orientation == 0.5 then --Facing SOUTH
        offset.y = 1
    end
    if orientation > 0.5 and orientation < 0.625 then -- Facing Hal-diagonal towards South from West
        offset.y = 2
        offset.x = -1
        radius = 2
    end
    if orientation == 0.625 then --Facing SOUTH WEST
        offset.y = 1
        offset.x = -1
    end
    if orientation > 0.625 and orientation < 0.75 then -- Facing Hal-diagonal towards West from South
        offset.y = 1
        offset.x = -2
        radius = 2
    end
    if orientation == 0.75 then --Facing WEST
        offset.x = -1
    end
    if orientation > 0.75 and orientation < 0.875 then -- Facing Hal-diagonal towards West from North
        offset.y = -1
        offset.x = -2
    end
    if orientation == 0.875 then --Facing NORTH WEST
        offset.y = -1
        offset.x = -1
    end
    if orientation > 0.875 and orientation < 1 then -- Facing Hal-diagonal towards North  from West
        offset.y = -2
        offset.x = -1
        radius = 2
    end

    
    location.position.x = location.position.x + offset.x
    location.position.y = location.position.y + offset.y
    local entities =  sardine.surface.find_entities_filtered{position = location.position, radius = radius, type="entity-ghost"}
    entities = filterEntityLayer(sardine, entities)

    local playerSelected = sardine.train.carriages[1].get_driver().selected
    if playerSelected ~= nil then 
        local ori = playerSelected.bounding_box.orientation
        if ori  == nil then ori = playerSelected.orientation end
        sardine.train.carriages[1].get_driver().create_local_flying_text{text=playerSelected.position.x.." "..playerSelected.position.y.." "..ori, position=playerSelected.position}
    end

    if #entities == 0 then
        entities = checkForRampGhost(sardine)
        if #entities == 0 then
            sardine.train.carriages[1].get_driver().create_local_flying_text{text="Pinged here, NR, r="..radius, position=location.position}
            return nil
        end
    end
    for i, v in pairs(entities) do
        sardine.train.carriages[1].get_driver().create_local_flying_text{text="Ghost found, r="..radius, position=v.position}
    end
    return entities[1]
end

---comment
---@param rail LuaEntity
---@param angle any Starting angle
function traceGhostLine(rail, angle)
    local rails = {}
    local difference = 0

end

---Ramp ghosts have a large sprite, this will search with the proper offsets.
---@param sardine LuaEntity
---@return (LuaEntity)[]
function checkForRampGhost(sardine)
    local orientation = sardine.draw_data.orientation
    local location = sardine.train.front_end.rail.position
    local offset = {x=0, y=0}
    local radius = 1

    if orientation == 0 then --Facing NORTH
        offset.y = -9
    end
    if orientation == 0.25 then --Facing East
        offset.x = 9
    end
    if orientation == 0.5 then --Facing South
        offset.y = 9
    end
    if orientation == 0.75 then --Facing West
        offset.x = -9
    end

    if string.find(sardine.train.front_end.rail.type, "straight") == nil then --If it's not a straight rail
        if string.find(sardine.train.front_end.rail.type, "curved") then --Then check if it's a curve rail
            if orientation > 0.875 or orientation < 0.125 then offset.y = -10 end --If it is a curve rail, we assume it could be a valid continuation (it's kinda weird, but ramps can connect to a specific kind of curved rail without a straight rail segment.)
            if orientation > 0.125 and orientation < 0.375 then offset.x = 10 end
            if orientation > 0.375 and orientation < 0.625 then offset.y = 10 end
            if orientation > 0.625 and orientation < 0.875 then offset.x = -10 end
        end
        sardine.train.carriages[1].get_driver().create_local_flying_text{text="Orientation: "..orientation, position=sardine.position}
    end

    location.x = location.x + offset.x
    location.y = location.y + offset.y
    
    local entities =  sardine.surface.find_entities_filtered{position = location, radius = radius, type="entity-ghost"}

    if #entities == 0 then return {} end

    local i = 1
    while i <= #entities do
        if entities[i].ghost_type ~= "rail-ramp" then
            table.remove(entities, i) --We avoid using a for loop to prevent skipping elements as table.remove() shifts values.
        else
            i = i + 1
        end
    end

    return entities
end

---Removes from an arr of entities any entities that are not on the same layer as the sardine.
---@param sardine LuaEntity
---@param entities (LuaEntity)[]
---@return (LuaEntity)[]
function filterEntityLayer(sardine, entities)
    local location = sardine.train.front_end.location
    local i = 1

    if location.rail_layer == 0 then -- Normal rail
        while i <= #entities do
            if string.find(entities[i].ghost_type, "elevated") ~= nil then
                table.remove(entities, i)
            else
                i = i + 1
            end
        end
    end

    if location.rail_layer == 1 then -- Elevated rail
        while i <= #entities do
            if string.find(entities[i].ghost_type, "elevated") == nil then
                table.remove(entities, i)
            else
                i = i + 1
            end
        end
    end

    return entities
end

function sardineLib.tickSardines()
    if #storage.data["tickingSardines"] == 0 then return end
    for index, value in pairs(storage.data["tickingSardines"]) do
        --sardineLib.scanTrack(value)
        getNextGhost(value)
    end
end

return sardineLib