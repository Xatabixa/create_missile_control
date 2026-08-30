-- Guidance system
-- Compatible with the current single-folder setup

local state = require("state")

local MAX_VECTOR = 0.25
local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 0.05
local DEADZONE = math.rad(0.5)

-- Shared state must already exist.
-- If it does not, guidance remains offline instead of crashing.

state.guidance = state.guidance or {
    online = false,
    status = "OFFLINE",
    active = false,
    commandX = 0,
    commandY = 0,
    yawError = 0,
    pitchError = 0
}

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function update()
    if state.navigation == nil then
        state.guidance.online = false
        state.guidance.active = false
        state.guidance.status = "OFFLINE"
        state.guidance.commandX = 0
        state.guidance.commandY = 0
        return
    end

    if not state.navigation.online then
        state.guidance.online = false
        state.guidance.active = false
        state.guidance.status = "OFFLINE"
        state.guidance.commandX = 0
        state.guidance.commandY = 0
        return
    end

    state.guidance.online = true
    state.guidance.status = "ONLINE"

    local bearing = state.navigation.bearing or 0
    local elevation = state.navigation.elevation or 0

    state.guidance.yawError = bearing
    state.guidance.pitchError = elevation

    local commandY = 0

    if math.abs(bearing) > DEADZONE then
        commandY = bearing * BEARING_GAIN
    end

    local commandX = 0

    if math.abs(elevation) > 0.5 then
        commandX = elevation * ELEVATION_GAIN
    end

    state.guidance.commandX =
        clamp(commandX, -MAX_VECTOR, MAX_VECTOR)

    state.guidance.commandY =
        clamp(commandY, -MAX_VECTOR, MAX_VECTOR)

    state.guidance.active =
        state.navigation.hasNavTarget == true
end

local function run()
    while state.system and state.system.running do
        update()
        sleep(0.05)
    end

    state.guidance.commandX = 0
    state.guidance.commandY = 0
    state.guidance.active = false
    state.guidance.online = false
    state.guidance.status = "OFFLINE"
end

return {
    run = run
}