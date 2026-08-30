-- Guidance module
-- Keeps the current control law unchanged; exposes a shared run() entry point.

local state = require("state")

local MAX_VECTOR = 0.25
local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 0.05
local DEADZONE = math.rad(0.5)

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function update()
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

    -- Navigation table reports signed vertical offset in blocks, not an angle.
    -- Keep this conservative until the full flight guidance model is implemented.
    local commandX = 0
    if math.abs(elevation) > 0.5 then
        commandX = elevation * ELEVATION_GAIN
    end

    state.guidance.commandX = clamp(commandX, -MAX_VECTOR, MAX_VECTOR)
    state.guidance.commandY = clamp(commandY, -MAX_VECTOR, MAX_VECTOR)
    state.guidance.active = state.navigation.hasNavTarget == true
end

local function run()
    while state.system.running do
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
