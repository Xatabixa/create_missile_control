-- Guidance module
-- Calculates guidance commands.
-- Thruster control is disabled during DRY TEST.

local state = require("state")

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local MAX_VECTOR = 0.25

local BEARING_GAIN = 1.0
local VERTICAL_GAIN = 1.0

--------------------------------------------------
-- CLAMP
--------------------------------------------------

local function clamp(value, minimum, maximum)

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
        state.guidance.status = "OFFLINE"

        state.guidance.commandX = 0
        state.guidance.commandY = 0

        return
    end

    state.guidance.online = true

    --------------------------------------------------
    -- BEARING COMMAND
    --------------------------------------------------

    local commandY =
        state.navigation.bearing *
        BEARING_GAIN

    --------------------------------------------------
    -- VERTICAL COMMAND
    --------------------------------------------------

    local commandX =
        state.navigation.verticalOffset *
        VERTICAL_GAIN

    --------------------------------------------------
    -- LIMIT
    --------------------------------------------------

    commandX =
        clamp(
            commandX,
            -MAX_VECTOR,
            MAX_VECTOR
        )

    commandY =
        clamp(
            commandY,
            -MAX_VECTOR,
            MAX_VECTOR
        )

    --------------------------------------------------
    -- STORE COMMAND
    --------------------------------------------------

    state.guidance.commandX =
        commandX

    state.guidance.commandY =
        commandY

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    if state.system.mode == "DRY TEST" then
        state.guidance.status = "DRY TEST"
    else
        state.guidance.status = "ACTIVE"
    end

    state.guidance.lastUpdate =
        os.clock()

    state.guidance.updateCount =
        state.guidance.updateCount + 1
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    update()

    sleep(0.05)
end

state.guidance.online = false
state.guidance.status = "OFFLINE"