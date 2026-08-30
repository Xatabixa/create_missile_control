-- Guidance module

local state = require("state")

local MAX_VECTOR = 0.25

local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 1.0

local DEADZONE =
    math.rad(0.5)

local function clamp(
    value,
    minimum,
    maximum
)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function update()

    if not state.navigation.online then

        state.guidance.online = false
        state.guidance.active = false

        state.guidance.commandX = 0
        state.guidance.commandY = 0

        return
    end

    state.guidance.online = true

    local bearing =
        state.navigation.bearing or 0

    local elevation =
        state.navigation.elevation or 0

    --------------------------------------------------
    -- YAW CORRECTION
    --------------------------------------------------

    local commandY = 0

    if math.abs(bearing) > DEADZONE then

        commandY =
            bearing *
            BEARING_GAIN

    end

    --------------------------------------------------
    -- PITCH CORRECTION
    --------------------------------------------------

    local commandX = 0

    if math.abs(elevation) > DEADZONE then

        commandX =
            elevation *
            ELEVATION_GAIN

    end

    state.guidance.commandX =
        clamp(
            commandX,
            -MAX_VECTOR,
            MAX_VECTOR
        )

    state.guidance.commandY =
        clamp(
            commandY,
            -MAX_VECTOR,
            MAX_VECTOR
        )

    state.guidance.active =
        state.navigation.hasNavTarget
end

while state.system.running do

    update()

    sleep(0.05)
end

state.guidance.commandX = 0
state.guidance.commandY = 0

state.guidance.active = false
state.guidance.online = false