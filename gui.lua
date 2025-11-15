-- gui time :(
local gui = {}
local sardineLib = require("__SARDINE__/sardineLib")
local modGui = require("mod-gui")

---Creates the GUI for a specific player.
---@param player LuaPlayer
function gui.createGui(player)
    local screen_element = player.gui.screen

    if screen_element["sardine-frame"] then return end

    local frame = screen_element.add{type = "frame", name = "sardine-frame", caption = {'SARDINE.name'}, style ="sardine-frame"}
    local mainVFlow =  frame.add{type = "flow", name="sardine-main-vflow", direction="vertical", style="sardine-main-vflow"}
    local innerFrame = mainVFlow.add{type="frame", name="sardine-inner-frame", direction = "vertical", style="sardine-inner-frame"}
    local costLabel = innerFrame.add{type="label", name="sardine-cost-label", caption= {'SARDINE.cost-label'}}
    local costSlots = innerFrame.add{type="scroll-pane", name="sardine-cost-slots", direction="vertical", style="sardine-cost-frame"}

    local line = innerFrame.add{type="line", name="sardine-bottom-line"}

    local bottomHFlow = innerFrame.add{type="flow", name="sardine-bottom-hflow", direction="horizontal", style="sardine-bottom-hflow"}
    local statusHFlow = bottomHFlow.add{type="flow", name="sardine-status-hflow", direction="horizontal", style="sardine-status-hflow"}
    local status = statusHFlow.add{type="sprite", name="sardine-status-indicator", sprite="utility/status_inactive", style="status_image"}
    local statusLabel = statusHFlow.add{type="label", name="sardine-status-label", caption={"SARDINE.status-idle"}}
    local jobButton = bottomHFlow.add{type="button", name="sardine-job-button", style="confirm_button", caption = {'SARDINE.job-button'}, enabled=false}

    local testInput = {
        {name="gun-turret", count=3},
        {name="gate", count=32},
        {name="artillery-turret", count=23},
        {name="barrel", count=64},
        {name="coal", count=3000},
        {name="coin", count=36},
        {name="stone", count=3},
        {name="wood", count=3},
        {name="train-stop", count=3}
    }

    --gui.updateCosts(player, testInput)
end

---Sets the state of an indicator light on the UI to indicate the status of the SARDINE occupied by the player.
---@param player LuaPlayer
---@param state "idle"|"scan"|"job"|"ready"|"error"
---@param error ? string Error text to display.
function gui.setStatusLabel(player, state, error)
    if player == nil then return end
    error = error or "invalid error! (please report this as a bug)"
    state = state or "idle"
    local screen_element = player.gui.screen
    if not screen_element["sardine-frame"] then return end
    local statusIndicator = screen_element["sardine-frame"]["sardine-main-vflow"]["sardine-inner-frame"]["sardine-bottom-hflow"]["sardine-status-hflow"]["sardine-status-indicator"]
    local statusLabel = screen_element["sardine-frame"]["sardine-main-vflow"]["sardine-inner-frame"]["sardine-bottom-hflow"]["sardine-status-hflow"]["sardine-status-label"]
    if state == "idle" then
        statusIndicator.sprite = "utility/status_inactive" --Values: status_working, status_not_working, status_yellow, status_blue, status_inactive
        statusLabel.caption = {'SARDINE.status-idle'}
    elseif state == "scan" then
        statusIndicator.sprite = "utility/status_yellow"
        statusLabel.caption = {'SARDINE.status-scanning'}
    elseif state == "job" then
        statusIndicator.sprite = "utility/status_yellow"
        statusLabel.caption = {'SARDINE.status-on-job'}
    elseif state == "ready" then
        statusIndicator.sprite = "utility/status_working"
        statusLabel.caption = {'SARDINE.status-ready'}
    elseif state == "error" then
        statusIndicator.sprite = "utility/status_not_working"
        statusLabel.caption = {'SARDINE.status-error'..error}
    end
end

---Sets the state of the start button
---@param player LuaPlayer
---@param state boolean
function gui.setButtonState(player, state)
    local screen_element = player.gui.screen
    if not screen_element["sardine-frame"] then return end

    local button = screen_element["sardine-frame"]["sardine-main-vflow"]["sardine-inner-frame"]["sardine-bottom-hflow"]["sardine-job-button"]

    gui.setStatusLabel(player, "ready")
    button.enabled = state
end

function gui.updateCosts(player, input)
    local screen_element = player.gui.screen
    if not screen_element["sardine-frame"] then return end

    local costSlots = screen_element["sardine-frame"]["sardine-main-vflow"]["sardine-inner-frame"]["sardine-cost-slots"]

    for key, row in pairs(costSlots.children) do
        row.destroy()
    end

    local row = costSlots.add{type="flow", name="sardine-cost-row-1", direction="horizontal", style="sardine-cost-row"}
    for index, item in ipairs(input) do
        row.add{type="sprite-button", name="sardine-cost-button-"..index, style="slot_button", sprite="item/"..item.name, number=item.count, tooltip="woohoooooooo"}
        if index % 8 == 0 then --Make a new row every 8 items
            row = costSlots.add{type="flow", name="sardine-cost-row-"..(index/8)+1, direction="horizontal", style="sardine-cost-row"}
        end
    end
end

---Destroys the UI for a specific player.
---@param player LuaPlayer
function gui.destroy(player)
    local screen_element = player.gui.screen
    if screen_element["sardine-frame"] then
        screen_element["sardine-frame"].destroy()
    end
end

function gui.createButton(player, state)
    local screen_element = player.gui.screen
    if screen_element["sardine-frame"] then
    end
end



return gui