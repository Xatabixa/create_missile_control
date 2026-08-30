-- Automatic guidance controller
-- Single-folder ComputerCraft compatible version

local MAX_VECTOR = 0.25

local BEARING_GAIN = 0.8
local ELEVATION_GAIN = 0.015

local BEARING_DEADZONE = math.rad(0.5)
local ELEVATION_DEADZONE = 0.5

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function update(state)
    local n = state.navigation
    local g = state.guidance

    if not n.online then
        g.online = false
        g.active = false
        g.status = "OFFLINE"

        g.commandX = 0
        g.commandY = 0

        return
    end

    g.online = true
    g.status = "ONLINE"

    local bearing = tonumber(n.bearing) or 0
    local elevation = tonumber(n.elevation) or 0

    g.yawError = bearing
    g.pitchError = elevation

    g.targetBearing = bearing
    g.targetElevation = elevation

    local commandY = 0
    local commandX = 0

    if math.abs(bearing) > BEARING_DEADZONE then
        commandY = bearing * BEARING_GAIN
    end

    if math.abs(elevation) > ELEVATION_DEADZONE then
        commandX = elevation * ELEVATION_GAIN
    end

    commandX = clamp(
        commandX,
        -MAX_VECTOR,
        MAX_VECTOR
    )

    commandY = clamp(
        commandY,
        -MAX_VECTOR,
        MAX_VECTOR
    )

    g.commandX = commandX
    g.commandY = commandY

    g.active =
        n.hasNavTarget == true
end

local function run(state)
    while state.system.running do
        update(state)
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