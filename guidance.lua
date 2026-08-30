-- Guidance System
-- Single-folder ComputerCraft compatible version
-- State is supplied by launcher.lua

local MAX_VECTOR = 0.25

local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 0.05

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

local function run(state)

    --------------------------------------------------
    -- Ensure guidance state exists
    --------------------------------------------------

    if type(state.guidance) ~= "table" then

        state.guidance = {
            online = false,
            status = "OFFLINE",

            active = false,

            commandX = 0,
            commandY = 0,

            yawError = 0,
            pitchError = 0
        }

    end

    --------------------------------------------------
    -- Update guidance calculation
    --------------------------------------------------

    local function update()

        --------------------------------------------------
        -- Navigation unavailable
        --------------------------------------------------

        if type(state.navigation) ~= "table" then

            state.guidance.online =
                false

            state.guidance.active =
                false

            state.guidance.status =
                "OFFLINE"

            state.guidance.commandX =
                0

            state.guidance.commandY =
                0

            return
        end

        if not state.navigation.online then

            state.guidance.online =
                false

            state.guidance.active =
                false

            state.guidance.status =
                "OFFLINE"

            state.guidance.commandX =
                0

            state.guidance.commandY =
                0

            return
        end

        --------------------------------------------------
        -- Navigation is online
        --------------------------------------------------

        state.guidance.online =
            true

        state.guidance.status =
            "ONLINE"

        --------------------------------------------------
        -- Read navigation errors
        --------------------------------------------------

        local bearing =
            tonumber(
                state.navigation.bearing
            ) or 0

        local elevation =
            tonumber(
                state.navigation.elevation
            ) or 0

        --------------------------------------------------
        -- Store errors
        --------------------------------------------------

        state.guidance.yawError =
            bearing

        state.guidance.pitchError =
            elevation

        --------------------------------------------------
        -- Calculate yaw command
        --------------------------------------------------

        local commandY = 0

        if math.abs(bearing) >
            DEADZONE then

            commandY =
                bearing *
                BEARING_GAIN
        end

        --------------------------------------------------
        -- Calculate pitch command
        --------------------------------------------------

        local commandX = 0

        if math.abs(elevation) >
            DEADZONE then

            commandX =
                elevation *
                ELEVATION_GAIN
        end

        --------------------------------------------------
        -- Limit commands
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
        -- Store commands
        --------------------------------------------------

        state.guidance.commandX =
            commandX

        state.guidance.commandY =
            commandY

        --------------------------------------------------
        -- Determine guidance activation
        --
        -- Target coordinates entered through
        -- the display are stored in state.target.
        --------------------------------------------------

        if type(state.target) == "table"
            and state.target.set == true then

            state.guidance.active =
                true

        else

            state.guidance.active =
                false

        end
    end

    --------------------------------------------------
    -- Main guidance loop
    --------------------------------------------------

    while state.system.running do

        update()

        sleep(0.05)

    end

    --------------------------------------------------
    -- Safe shutdown
    --------------------------------------------------

    state.guidance.commandX = 0
    state.guidance.commandY = 0

    state.guidance.active =
        false

    state.guidance.online =
        false

    state.guidance.status =
        "OFFLINE"
end

return {
    run = run
}