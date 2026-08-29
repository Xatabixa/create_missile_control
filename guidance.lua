-- Guidance module
-- Calculates nozzle commands from navigation data.
-- Does NOT control the thruster directly.

local state = require("state")

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local MAX_VECTOR = 0.25

local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 1.0

local DEADZONE = math.rad(0.5)

--------------------------------------------------
-- CLAMP
--------------------------------------------------

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

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    if not state.navigation.online then

        state.guidance.online = false

        return

    end

    state.guidance.online = true

    local bearing =
        state.navigation.bearing

    local elevation =
        state.navigation.elevation

    --------------------------------------------------
    -- Y AXIS
    --
    -- Y+ = RIGHT
    -- Y- = LEFT
    --------------------------------------------------

    local commandY = 0

    if math.abs(bearing) > DEADZONE then

        commandY =
            bearing *
            BEARING_GAIN

    end

    --------------------------------------------------
    -- X AXIS
    --
    -- X+ = FORWARD
    -- X- = BACKWARD
    --
    -- Vertical correction will be calibrated later.
    --------------------------------------------------

    local commandX = 0

    if math.abs(elevation) > DEADZONE then

        commandX =
            elevation *
            ELEVATION_GAIN

    end

    --------------------------------------------------
    -- LIMIT
    --------------------------------------------------

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

end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    update()

    sleep(0.05)

end
