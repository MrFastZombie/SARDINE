local sardineLib = {}

---Initialize the mod's data.
function sardineLib.initData()
    storage.data = storage.data or {}
    if not storage.data["tickingSardines"] then storage.data["tickingSardines"] = {} end
    if not storage.data["sardinesOnJob"] then storage.data["sardinesOnJob"] = {} end
    if not storage.data["sardineWorkTiles"] then storage.data["sardineWorkTiles"] = {} end
    if not storage.data["sardineWorkOrients"] then storage.data["sardineWorkOrients"] = {} end
end

---Add a sardine to the list of vehicles that should be running their on tick events
---@param sardine LuaEntity
function sardineLib.startTicking(sardine)
    if sardineLib.checkJobState(sardine) then return end
    if sardineLib.checkTickState(sardine) then return end
    storage.data["tickingSardines"][sardine.train.id] = sardine
end

---Remove a sardine from the ticking list
---@param sardine LuaEntity
function sardineLib.stopTicking(sardine) --Stop ticking when: player is found to not be in vehicle, when a vehicle has been given a task
    if sardineLib.checkTickState(sardine) == false then return end
    table.remove(storage.data["tickingSardines"],sardine.train.id)
end

---Starts ticking a sardine's job. Also stores the given entity list in the Sardine's job data for future reference.
---@param sardine LuaEntity
---@param entityList (LuaEntity)[]
function sardineLib.startJob(sardine, entityList, orientationList)
    if sardineLib.checkTickState(sardine) then sardineLib.stopTicking(sardine) end
    if sardineLib.checkJobState(sardine) then return end
    if storage.data["sardineWorkTiles"] == nil or storage.data["sardineWorkOrients"] == nil then sardineLib.initData() end
    storage.data["sardineWorkTiles"][sardine.train.id] = entityList
    storage.data["sardineWorkOrients"][sardine.train.id] = orientationList
    storage.data["sardinesOnJob"][sardine.train.id] = sardine
end

---Stops ticking a sardine's job
---@param sardine LuaEntity
function sardineLib.stopJob(sardine) --Stop ticking when: player is found to not be in vehicle, when a vehicle has been given a task
    if sardineLib.checkJobState(sardine) == false then return end
    table.remove(storage.data["sardinesOnJob"],sardine.train.id)
    table.remove(storage.data["sardineWorkTiles"],sardine.train.id)
    table.remove(storage.data["sardineWorkOrients"],sardine.train.id)
end

---Gets the list of entities on a sardine's job.
---@param sardine LuaEntity
---@return (LuaEntity)[]|nil
function sardineLib.getSardineJobEntityList(sardine)
    if storage.data["sardineWorkTiles"] == nil then return nil end
    if storage.data["sardineWorkTiles"][sardine.train.id] == nil then return nil end
    local list = storage.data["sardineWorkTiles"][sardine.train.id]
    return list
end

---Gets the list of entity orientations on a sardine's job.
---@param sardine LuaEntity
---@return (number)[]|nil
function sardineLib.getSardineJobOrientationList(sardine)
    if storage.data["sardineWorkOrients"] == nil then return nil end
    if storage.data["sardineWorkOrients"][sardine.train.id] == nil then return nil end
    local list = storage.data["sardineWorkOrients"][sardine.train.id]
    return list
end

---Checks if a rail is in the job list of a SARDINE.
---@param rail LuaEntity
---@param sardine LuaEntity
---@return boolean
function railIsWorkEntity(rail, sardine)
    local list = sardineLib.getSardineJobEntityList(sardine)
    if list == nil then return false end
    for key, value in pairs(list) do
        if value.valid then
            if value.unit_number == rail.unit_number then return true end
        end
    end
    return false
end

---Check if a sardine is set to tick.
---@param sardine LuaEntity
---@return boolean
function sardineLib.checkTickState(sardine)
    if storage.data["tickingSardines"][sardine.train.id] then return true
    else return false
    end
end

---Check if a sardine is currently on a job
---@param sardine any
---@return boolean
function sardineLib.checkJobState(sardine)
    if storage.data["sardinesOnJob"][sardine.train.id] then return true
    else return false
    end
end


---Get a S.A.R.D.I.N.E by ID
---@param id any
function sardineLib.getSardine(id)
end

---Get the last rail. Old function, probably best not to rely on it. 
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

---Gets the relative orientation of a rail compared to SARDINE. Another old function that might need to be redone or removed, but no issues stemming from it are apparent yet.
---@param rail LuaEntity
---@param sardine LuaEntity
function getRelativeOrientation(rail, sardine)
    local orientation = snapOrientation(sardine.draw_data.orientation)
    local newOrientation = 0
    local difference = 0

    if rail == nil or sardine == nil then return nil end

    if rail.bounding_box.orientation ~= nil then
        newOrientation = rail.bounding_box.orientation else newOrientation = rail.orientation
    end

    difference = math.abs(orientation - newOrientation)

    if orientation <= 0.5 then
        if difference > 0.125 then orientation = newOrientation + 0.5
        ---@diagnostic disable-next-line: cast-local-type
        else orientation = newOrientation  end
    end

    if orientation > 0.5 then 
        if orientation > 0.875 then --This value doesn't matter much as long as it's not too close to 0.5
            if newOrientation == 0 then
                orientation = newOrientation
            end
        else orientation = newOrientation + 0.5 end
    end

    --[[if rail.name == "entity-ghost" then
        if string.find(rail.ghost_type, "curved-rail", 1, true) ~= nil then
            ---@diagnostic disable-next-line: cast-local-type
            orientation = newOrientation
        end
    end]]--

    while orientation > 1 do orientation =  orientation - 1 end

    return orientation
end

---Helper function, displays floating debug text when debugging is enabled.
---@param msg string
---@param pos {x:number, y:number}
function debugFlyMsg(msg, pos)
    local debug = true
    --TODO: Add a debug setting.
    if debug == true then
        if #storage.data["tickingSardines"] == 0 then return end
        for index, value in pairs(storage.data["tickingSardines"]) do
            value.train.carriages[1].get_driver().create_local_flying_text{text=msg, position=pos}
        end
    end
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
            if isRailElevated(entities[1]) and isRailRamp(entities[1]) == false then
                table.remove(entities, i)
            else
                i = i + 1
            end
        end
    end

    if location.rail_layer == 1 then -- Elevated rail
        while i <= #entities do
            if isRailElevated(entities[1]) == false and isRailRamp(entities[1]) == false then
                table.remove(entities, i)
            else
                i = i + 1
            end
        end
    end

    return entities
end

---Checkes if an entity is a rail ramp.
---@param entity LuaEntity
function isRailRamp(entity)
    if entity.name == "entity-ghost" then
        if entity.ghost_name == "rail-ramp" then
            return true
        end
    end

    if entity.name == "rail-ramp" then return true end

    return false
end

---Checks if the given rail is elevated.
---@param rail LuaEntity
---@return boolean
function isRailElevated(rail)
    if rail.name == "entity-ghost" then
        if string.find(rail.ghost_type, "elevated") ~= nil then return true end
    elseif string.find(rail.type, "elevated") ~= nil then return true end
    return false
end

---Snaps orientation to a valid direction.
---@param orientation any
---@return number
function snapOrientation(orientation)
    local smallestDifference = 0.9375
    local pick = 0
    local validOrientations = {[0]=0, [0.0625]=0.0625, [0.125]=0.125, [0.1875]=0.1875, [0.25]=0.25, [0.3125]=0.3125, [0.375]=0.375, [0.4375]=0.4375, [0.5]=0.5, [0.5625]=0.5625, [0.625]=0.625, [0.6875]=0.6875, [0.75]=0.75, [0.8125]=0.8125, [0.875]=0.875, [0.9375]=0.9375}
    if validOrientations[orientation] ~= nil then
        return orientation
    else
        for index, value in pairs(validOrientations) do
            local difference = orientation - value
            if math.abs(difference) < smallestDifference then
                smallestDifference = math.abs(difference)
                pick = value
            end
        end
    end
    return pick
end

---Gives an array of detected rail ghosts that are potential traversals from the given piece. First piece should always be the natural traversal, which is always a right turn when given 2 turns and no straight.
---@param rail LuaEntity
---@param movementOrientation number
---@param sardine LuaEntity
---@return (LuaEntity)[]
function getPossibleTraversalPieces(rail, movementOrientation, sardine)
    local railType = nil
        if rail.name ~= "entity-ghost" then railType = rail.name
        else railType = rail.ghost_type end
    local elevated = isRailElevated(rail)
    local offsetMult = {x=1,y=1}
    local checkTiles = {}

    --- QUADRANT OFFSET ---
    if movementOrientation >= 0 and movementOrientation <= 0.25 then --First quadrant
        offsetMult.y = -1
    elseif movementOrientation > 0.5 and movementOrientation <= 0.75 then --Third quadrant | Skipped the second quadrant as that is the default mult.
        offsetMult.x = -1
    elseif movementOrientation > 0.75 then --Fourth quadrant
        offsetMult.x = -1
        offsetMult.y = -1
    end
    --- END OF QUADRANT OFFSET ---

    local snappedOrientation = snapOrientation(movementOrientation)

    --Explanation of the code below:
    --The code checks the rail type and adds all of its potential traversal pieces to a list that is then checked below.
    --When the traversal pieces are checked, the entity search function filters to just that piece type and whatever offset was given.
    --The quadrant offset code above sets the polarity of the offsets below.
    --Some pieces need special action. For example, straight rail has to be offset along its traversal direction. (i.e. a piece facing north or south needs to be offset along the Y axis.)
    --See the table picture in the reference folder to see all the conditions I am checking for.
    if railType == "straight-rail" or railType == "elevated-straight-rail"  then --Straight rail & Diagonal Straight Rail
        if snappedOrientation == 0 or snappedOrientation == 0.5 or snappedOrientation == 0.9375 or snappedOrientation == 0.0625 or snappedOrientation == 0.4375 or snappedOrientation == 0.5625 then --North/South
            table.insert(checkTiles,{
                "straight-rail", {x=0,y=2*offsetMult.y}
            })
            table.insert(checkTiles,{
                "curved-rail-a", {x=0,y=3*offsetMult.y}
            })
            table.insert(checkTiles,{
                "rail-ramp", {x=0,y=9*offsetMult.y}
            })
        elseif snappedOrientation == 0.25 or snappedOrientation == 0.75 or snappedOrientation == 0.1875 or snappedOrientation == 0.3125 or snappedOrientation == 0.6875 or snappedOrientation == 0.8125 then --East/West
            table.insert(checkTiles,{
                "straight-rail", {x=2*offsetMult.x,y=0}
            })
            table.insert(checkTiles,{
                "curved-rail-a", {x=3*offsetMult.x,y=0}
            })
            table.insert(checkTiles,{
                "rail-ramp", {x=9*offsetMult.x,y=0}
            })
        elseif snappedOrientation == 0.375 or snappedOrientation == 0.875 or snappedOrientation == 0.125 or snappedOrientation == 0.625 then --Diagonal straight rail, any direction
            table.insert(checkTiles, {
                "curved-rail-b", {x=3*offsetMult.x,y=3*offsetMult.y}
            })
            table.insert(checkTiles, {
                "straight-rail", {x=2*offsetMult.x,y=2*offsetMult.y}
            })
        else
            log("SARDINE: Found a "..railType.." but the orientation was unexpected! Snapped Orientation: " ..snappedOrientation) --This probably isn't going to happen but I know better to ignore edge cases.
        end
    elseif railType == "half-diagonal-rail" or railType == "elevated-half-diagonal-rail" then --Half-diagonal rail
        table.insert(checkTiles, {
            "curved-rail-a", {x=2*offsetMult.x,y=5*offsetMult.y}
        })
        table.insert(checkTiles, {
            "curved-rail-a", {x=5*offsetMult.x,y=2*offsetMult.y}
        })
        table.insert(checkTiles, {
            "curved-rail-b", {x=2*offsetMult.x,y=4*offsetMult.y}
        })
        table.insert(checkTiles, {
            "curved-rail-b", {x=4*offsetMult.x,y=2*offsetMult.y}
        })
        table.insert(checkTiles, {
            "half-diagonal-rail", {x=2*offsetMult.x,y=4*offsetMult.y}
        })
        table.insert(checkTiles, {
            "half-diagonal-rail", {x=4*offsetMult.x,y=2*offsetMult.y}
        })
    elseif railType == "curved-rail-a" or railType == "elevated-curved-rail-a"  then --Curved rail A
        local tileQueue = {} --This one needs a queue to handle swapping values conditionally.
        table.insert(tileQueue, {
            "straight-rail", {x=0,y=3} --Offset multiplier waits until the offset value is finalized below.
        })
        table.insert(tileQueue, {
            "curved-rail-a", {x=0,y=4}
        })
        table.insert(tileQueue, {
            "curved-rail-a", {x=2,y=6}
        })
        table.insert(tileQueue, {
            "curved-rail-b", {x=2,y=5}
        })
        table.insert(tileQueue, {
            "half-diagonal-rail", {x=2,y=5}
        })
        table.insert(tileQueue, {
            "rail-ramp", {x=0,y=10}
        })
        for index, tile in ipairs(tileQueue) do --Swapping values when moving horizontally and applying offset multiplier after.
            local tempX = 0
            local tempY = 0
            if (snappedOrientation >= 0.6875 and snappedOrientation <= 0.875) or (snappedOrientation >= 0.1875 and snappedOrientation <= 0.3125) then --Swapping
                tempX = tile[2].x
                tempY = tile[2].y
                tile[2].x = tempY
                tile[2].y = tempX
            end
            tile[2].x = tile[2].x*offsetMult.x --Apply offsets
            tile[2].y = tile[2].y*offsetMult.y
            table.insert(checkTiles, tile) --Send to main queue
        end
    elseif railType == "curved-rail-b" or railType == "elevated-curved-rail-b"  then --Curved rail B
        table.insert(checkTiles, {
            "curved-rail-a", {x=2*offsetMult.x,y=5*offsetMult.y}
        })
        table.insert(checkTiles, {
            "curved-rail-a", {x=5*offsetMult.x,y=2*offsetMult.y}
        })
        table.insert(checkTiles, {
            "curved-rail-b", {x=2*offsetMult.x,y=4*offsetMult.y}
        })
        table.insert(checkTiles, {
            "curved-rail-b", {x=4*offsetMult.x,y=2*offsetMult.y}
        })
        table.insert(checkTiles, { --This one is probably only needed when the SARDINE travels in the same direction as the curved rail's bounding box orientation.
            "curved-rail-b", {x=4*offsetMult.x,y=4*offsetMult.y}
        })
        table.insert(checkTiles, {
            "straight-rail", {x=3*offsetMult.x,y=3*offsetMult.y}
        })
        table.insert(checkTiles, {
            "half-diagonal-rail", {x=2*offsetMult.x,y=4*offsetMult.y}
        })
        table.insert(checkTiles, {
            "half-diagonal-rail", {x=4*offsetMult.x,y=2*offsetMult.y}
        })
    elseif railType == "rail-ramp" then -- Rail ramp
        local tileQueue = {} --Once again needs a queue. I probably could've done this with the straight rails too.
        table.insert(tileQueue, {
            "straight-rail", {x=0,y=9}
        })
        table.insert(tileQueue, {
            "curved-rail-a", {x=0,y=10}
        })
        table.insert(tileQueue, {
            "rail-ramp", {x=0,y=16}
        })
        for index, tile in ipairs(tileQueue) do
            local tempX = 0
            local tempY = 0
            if snappedOrientation == 0.75 or snappedOrientation == 0.25 then --Horizontal
                tempX = tile[2].x
                tempY = tile[2].y
                tile[2].x = tempY
                tile[2].y = tempX
            end
            tile[2].x = tile[2].x*offsetMult.x --Apply offsets
            tile[2].y = tile[2].y*offsetMult.y
            table.insert(checkTiles, tile) --Send to main queue
        end
    end

    local output = {}

    if rail.name == "entity-ghost" then --Setting elevated to true when going up a ramp. (I think it'll become false when going down a ramp on its own.)
        if rail.ghost_name == "rail-ramp" then
            if rail.orientation == snappedOrientation then elevated = true end
        end
    end
    if rail.name == "rail-ramp" then --Not sure if this is necessary but it doesn't hurt.
        if rail.orientation == snappedOrientation then elevated = true end
    end


    for index, tile in ipairs(checkTiles) do --Search all the potential spots.
        local name = tile[1]
        if elevated and name ~= "rail-ramp" then name = "elevated-"..name end --If elevated and not a ramp, add elevated to the name.
        local position = rail.position
        position.x = position.x+tile[2].x
        position.y = position.y+tile[2].y
        local found = rail.surface.find_entities_filtered{position = position, radius = 1, type="entity-ghost", ghost_name=name}
        for index, entity in ipairs(found) do
            table.insert(output, entity)
        end
        --[[if #output == 0 and #found ~= 0 then
            output = found
        elseif #found ~= 0 then
            output = {table.unpack(output), table.unpack(found) }
        end]]--
    end

    --[[if railType ~= "rail-ramp" then
        output = filterEntityLayer(sardine, output)
    end]]--

    for index, value in ipairs(output) do
        debugFlyMsg("Potential traverse ", {x=value.position.x, y=value.position.y-(index*0.5)})
        --sardine.train.carriages[1].get_driver().create_local_flying_text{text="Potential traverse ", position={x=value.position.x, y=value.position.y-(index*0.5)}}
    end

    output = removePerpendicular(output, rail) --To prevent accidentally jumping to a perpendicular rail line.
    output = SortOrientations(output, movementOrientation) --To ensure the natural direction is the first returned element.
    
    if #output > 0 then --Debug msg that informs which rail piece was selected to be first.
        local pickedOrientation = output[1].bounding_box.orientation
        if pickedOrientation == nil then pickedOrientation = output[1].orientation end
        if #output > 1 then debugFlyMsg("Picked rail w/ orientation: "..pickedOrientation, {x=output[1].position.x,y=output[1].position.y-5}) end
    end

    return output
end

---Removes perpendicular tiles from tile list, to prevent false-positives.
---@param input (LuaEntity)[]
---@param rail LuaEntity
---@return (LuaEntity)[]
function removePerpendicular(input, rail)
    local output = input
    if #output == 0 then return output end --Return early to avoid calling unncessesary code.

    local railOrientation = rail.bounding_box.orientation
    if railOrientation == nil then railOrientation = rail.orientation end --Use the input rail orientation to figure out what axis we're on. Don't need to worry about which side of the axis we're moving.

    local i = 1
    while i <= #output do --Using a while loop to prevent iteration issues.
        local entityOrientation = output[i].bounding_box.orientation
        if entityOrientation == nil then entityOrientation = output[i].orientation end
        local difference = math.min(math.abs(railOrientation - entityOrientation), 1-math.abs(railOrientation - entityOrientation)) --spooky math that basically gets the difference between two points on a cyclical system

        if (difference >= 0.1875 and difference <= 0.3125) or (difference >= 0.6875 and difference <= 0.8125) then
            table.remove(output, i) --We avoid using a for loop to prevent skipping elements as table.remove() shifts values.
        else
            i = i + 1
        end
    end

    return output
end

---Traces a line of ghost rails until the end is reached or maximum number of rails is traced.
---@param sardine LuaEntity Train to source initial orientation from.
---@param rail LuaEntity|nil Rail to start tracing from.
---@return (LuaEntity)[], (number)[]
function traceGhostLine(sardine, rail)
    local rails = {}
    local orientations = {}
    local difference = 0
    local curRail = rail
    local lastRail = nil
    local orientation = sardine.draw_data.orientation
    local newOrientation = 0

    while curRail ~= nil do --This is probably easier to do if you're good at trig
        table.insert(rails, curRail)
        table.insert(orientations, orientation)
        lastRail = curRail
        dFromZero = math.abs(0-orientation)
        dFromHalf = math.abs(orientation-0.5)
        if curRail == nil then break end
        --if orientation == 1 then orientation = 0 end
        --if orientation > 1 then orientation = orientation - 1 end
        if curRail.bounding_box.orientation ~= nil then newOrientation = curRail.bounding_box.orientation else newOrientation = curRail.orientation end
        difference = math.min(math.abs(orientation - newOrientation), 1-math.abs(orientation - newOrientation))

        if difference > 0.125 then
            orientation = newOrientation + 0.5 --Presumably, if a traversal piece is more than 0.125 off then it is just reporting the wrong side of the axis so we flip it. (The cyclic system has a range of 0-1)
        else
            ---@diagnostic disable-next-line: cast-local-type
            orientation = newOrientation
        end

        --[[if curRail.name == "entity-ghost" then
            if string.find(curRail.ghost_type, "curved-rail", 1, true) ~= nil then
                ---@diagnostic disable-next-line: cast-local-type
                orientation = newOrientation
            end
        end]]--

        while orientation > 1 do orientation =  orientation - 1 end --If the number ends up above 1, we remove 1 until it is below to get the actual number.

        orientation = snapOrientation(orientation)

        --curRail = getNextGhost(sardine, curRail, orientation)
        --debugFlyMsg("Ori: "..orientation.." Diff: "..difference, {x=curRail.position.x, y=curRail.position.y+2})
        local traversal = getPossibleTraversalPieces(curRail, orientation, sardine)
        if #traversal > 0 then curRail = traversal[1] end
        if lastRail == curRail then break end
        if #rails >= 2500 then
            log("SARDINE REACHED MAXIMUM RAIL COUNT")
            break
        end
    end

    for index, value in ipairs(rails) do
        debugFlyMsg("Traced", value.position)
    end

    table.insert(orientations, orientation)
    return rails, orientations
end

---Sorts a list of rails by closest orientation to the given SARDINE.
---@param input (LuaEntity)[]
---@param movementOrientation number
---@return (LuaEntity)[]
function SortOrientations(input, movementOrientation)
    local baseOrientation = movementOrientation

    --[[if rail.bounding_box.orientation then
        baseOrientation = rail.bounding_box.orientation
    else
        baseOrientation = rail.orientation
     end]]--

    local output = {}
    for index, entity in ipairs(input) do
        local railOrientation = 0
        local difference = 0
        if #output == 0 then table.insert(output, entity)
        else
            if entity.bounding_box.orientation ~= nil then
                railOrientation = entity.bounding_box.orientation else railOrientation = entity.orientation
            end

            --difference = math.abs(baseOrientation - railOrientation)
            difference = snapOrientation(math.min(math.abs(baseOrientation - railOrientation), 1-math.abs(baseOrientation - railOrientation)))

            for jindex, element in ipairs(output) do
                local compareOrientation = 0

                if element.bounding_box.orientation ~= nil then
                    compareOrientation = element.bounding_box.orientation else compareOrientation = element.orientation
                end

                --local compareDifference = math.abs(baseOrientation - compareOrientation)
                local compareDifference = snapOrientation(math.min(math.abs(baseOrientation - compareOrientation), 1-math.abs(baseOrientation - compareOrientation)))

                if difference < compareDifference then
                    table.insert(output, jindex, entity)
                    break
                end
                if difference == compareDifference then --If difference is equal, we must attempt to select the right turn. 
                    local goRight = baseOrientation + 0.0625 --Turn right a bit.
                    if goRight >= 1 then goRight = goRight - 1 end
                    local newDifference = snapOrientation(math.min(math.abs(goRight - railOrientation), 1-math.abs(goRight - railOrientation)))
                    compareDifference = snapOrientation(math.min(math.abs(baseOrientation - compareOrientation), 1-math.abs(baseOrientation - compareOrientation)))
                    if newDifference < compareDifference then
                        table.insert(output, jindex, entity)
                        break
                    end
                end
                if jindex >= #output then
                    table.insert(output, entity)
                    break
                end
            end
        end
    end

    return output
end

---Ticks active sardines, allowing them to perform their duties if needed. Generally, they should only tick when there is a driver or while performing a job.
function sardineLib.tickSardines()
    if #storage.data["tickingSardines"] == 0 then return end
    for index, value in pairs(storage.data["tickingSardines"]) do
        local playerSelected = value.train.carriages[1].get_driver().selected
        if playerSelected ~= nil then 
            getPossibleTraversalPieces(playerSelected, value.draw_data.orientation, value)

            local msgOri
            if playerSelected.bounding_box.orientation ~= nil then
                msgOri = playerSelected.bounding_box.orientation else msgOri = playerSelected.orientation
            end

            if playerSelected.name == "entity-ghost" then debugFlyMsg("Entity ori: "..msgOri.." True Orientation: "..getRelativeOrientation(playerSelected, value).. " Train orientation: "..snapOrientation(value.draw_data.orientation), value.train.carriages[1].position) end
            if playerSelected.name == "entity-ghost" then debugFlyMsg(playerSelected.ghost_name.. " "..playerSelected.position.x.." "..playerSelected.position.y, playerSelected.position) end
        end

        local ghost =  getPossibleTraversalPieces(value.train.front_end.rail, value.draw_data.orientation, value)[1]

        if ghost ~= nil then
            traceGhostLine(value, ghost)
        end
    end
end

return sardineLib