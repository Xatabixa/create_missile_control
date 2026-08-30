-- Guidance System
-- Uses live navigation data from the shared state.
-- Designed for dry testing before automatic actuator control.

local MAX_VECTOR = 0.25

local YAW_GAIN = 1.0
local PITCH_GAIN = 0.05

local YAW_DEADZONE = math.rad(0.5)
local PITCH_DEADZONE = math.rad(0.5)

local function clamp(value, minimum, maximum)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function normalizeAngle(angle)

    while angle > math.pi do
        angle = angle - math.pi * 2
    end

    while angle < -math.pi do
        angle = angle + math.pi * 2
    end

    return angle
end

local function run(state)

    --------------------------------------------------
    -- Ensure guidance state exists
    --------------------------------------------------

    state.guidance =
        state.guidance or {
            online = false,
            status = "OFFLINE",

            active = false,

            commandX = 0,
            commandY = 0,

            yawError = 0,
            pitchError = 0
        }

    --------------------------------------------------
    -- Main update
    --------------------------------------------------

    local function update()

        local navigation =
            state.navigation

        if type(navigation) ~= "table" then

            state.guidance.online =
                false

            state.guidance.status =
                "OFFLINE"

            state.guidance.active =
                false

            state.guidance.commandX =
                0

            state.guidance.commandY =
                0

            return
        end

        if not navigation.online then

            state.guidance.online =
                false

            state.guidance.status =
                "OFFLINE"

            state.guidance.active =
                false

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
        -- YAW
        --
        -- IMPORTANT:
        -- Use relativeAngle instead of bearing.
        --
        -- relativeAngle is updated by navigation.lua
        -- from navigation_table:getRelativeAngleRad().
        --
        -- This value should change when the missile
        -- rotates relative to the target.
        --------------------------------------------------

        local yawError =
            tonumber(
                navigation.relativeAngle
            ) or 0

        yawError =
            normalizeAngle(
                yawError
            )

        state.guidance.yawError =
            yawError

        --------------------------------------------------
        -- PITCH
        --
        -- navigation.elevation is a vertical offset,
        -- not an angle.
        --
        -- Convert vertical offset and distance into
        -- a desired elevation angle.
        --------------------------------------------------

        local verticalOffset =
            tonumber(
                navigation.elevation
            ) or 0

        local distance =
            tonumber(
                navigation.distance
            ) or 0

        local desiredPitch =
            0

        if distance > 0.001 then

            local horizontalDistance =
                math.sqrt(
                    math.max(
                        distance * distance -
                        verticalOffset * verticalOffset,
                        0
                    )
                )

            desiredPitch =
                math.atan(
                    verticalOffset,
                    math.max(
                        horizontalDistance,
                        0.001
                    )
                )
        end

        --------------------------------------------------
        -- Current missile pitch
        --------------------------------------------------

        local currentPitch =
            tonumber(
                navigation.pitch
            ) or 0

        --------------------------------------------------
        -- Pitch error
        --------------------------------------------------

        local pitchError =
            desiredPitch -
            currentPitch

        pitchError =
            normalizeAngle(
                pitchError
            )

        state.guidance.pitchError =
            pitchError

        --------------------------------------------------
        -- YAW COMMAND
        --------------------------------------------------

        local commandY =
            0

        if math.abs(yawError) >
            YAW_DEADZONE then

            commandY =
                yawError *
                YAW_GAIN
        end

        --------------------------------------------------
        -- PITCH COMMAND
        --------------------------------------------------

        local commandX =
            0

        if math.abs(pitchError) >
            PITCH_DEADZONE then

            commandX =
                pitchError *
                PITCH_GAIN
        end

        --------------------------------------------------
        -- Limit actuator commands
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
        -- Publish commands
        --------------------------------------------------

        state.guidance.commandX =
            commandX

        state.guidance.commandY =
            commandY

        --------------------------------------------------
        -- Guidance activation
        --
        -- Our display target is accepted, but the
        -- navigation table target is also accepted.
        --------------------------------------------------

        local localTarget =
            type(state.target) == "table"
            and state.target.set == true

        local navigationTarget =
            navigation.hasNavTarget == true

        state.guidance.active =
            localTarget or navigationTarget
    end

    --------------------------------------------------
    -- Continuous guidance loop
    --------------------------------------------------

    while state.system
        and state.system.running do

        update()

        sleep(0.05)
    end

    --------------------------------------------------
    -- Safe shutdown
    --------------------------------------------------

    state.guidance.commandX =
        0

    state.guidance.commandY =
        0

    state.guidance.yawError =
        0

    state.guidance.pitchError =
        0

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