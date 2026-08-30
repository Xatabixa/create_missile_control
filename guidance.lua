-- Guidance System
-- Continuous proportional guidance controller.
-- Designed for safe dry testing with a frozen missile.

--------------------------------------------------
-- CONTROLLER LIMITS
--------------------------------------------------

local MAX_VECTOR = 0.25

-- Proportional gains.
-- Lower values produce smoother actuator commands.

local YAW_GAIN = 0.0025
local PITCH_GAIN = 0.05

-- Dead zones.

local YAW_DEADZONE = math.rad(0.5)
local PITCH_DEADZONE = math.rad(0.5)

-- Maximum command change per update.
-- Guidance updates every 0.05 seconds.

local MAX_COMMAND_STEP = 0.025

--------------------------------------------------
-- UTILITY FUNCTIONS
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

local function normalizeAngle(
    angle
)

    while angle > math.pi do

        angle =
            angle -
            math.pi * 2

    end

    while angle < -math.pi do

        angle =
            angle +
            math.pi * 2

    end

    return angle
end

--------------------------------------------------

local function approach(
    current,
    target,
    maximumStep
)

    local difference =
        target - current

    if difference >
        maximumStep then

        return current +
            maximumStep

    end

    if difference <
        -maximumStep then

        return current -
            maximumStep

    end

    return target
end

--------------------------------------------------
-- MAIN MODULE
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- INITIALIZE GUIDANCE STATE
    --------------------------------------------------

    state.guidance =
        state.guidance or {}

    state.guidance.online =
        false

    state.guidance.status =
        "STARTING"

    state.guidance.active =
        false

    state.guidance.commandX =
        0

    state.guidance.commandY =
        0

    state.guidance.yawError =
        0

    state.guidance.pitchError =
        0

    --------------------------------------------------
    -- INTERNAL COMMAND STATE
    --------------------------------------------------

    local currentCommandX =
        0

    local currentCommandY =
        0

    --------------------------------------------------
    -- UPDATE FUNCTION
    --------------------------------------------------

    local function update()

        local navigation =
            state.navigation

        --------------------------------------------------
        -- NAVIGATION CHECK
        --------------------------------------------------

        if type(navigation) ~= "table" then

            state.guidance.online =
                false

            state.guidance.status =
                "NAV OFFLINE"

            state.guidance.active =
                false

            currentCommandX =
                approach(
                    currentCommandX,
                    0,
                    MAX_COMMAND_STEP
                )

            currentCommandY =
                approach(
                    currentCommandY,
                    0,
                    MAX_COMMAND_STEP
                )

            state.guidance.commandX =
                currentCommandX

            state.guidance.commandY =
                currentCommandY

            return
        end

        if not navigation.online then

            state.guidance.online =
                false

            state.guidance.status =
                "NAV OFFLINE"

            state.guidance.active =
                false

            currentCommandX =
                approach(
                    currentCommandX,
                    0,
                    MAX_COMMAND_STEP
                )

            currentCommandY =
                approach(
                    currentCommandY,
                    0,
                    MAX_COMMAND_STEP
                )

            state.guidance.commandX =
                currentCommandX

            state.guidance.commandY =
                currentCommandY

            return
        end

        --------------------------------------------------
        -- NAVIGATION ONLINE
        --------------------------------------------------

        state.guidance.online =
            true

        state.guidance.status =
            "ONLINE"

        --------------------------------------------------
        -- TARGET CHECK
        --------------------------------------------------

        local localTarget =
            type(state.target) == "table"
            and state.target.set == true

        local navigationTarget =
            navigation.hasNavTarget == true

        state.guidance.active =
            localTarget or navigationTarget

        --------------------------------------------------
        -- READ HEADING
        --------------------------------------------------

        local heading =
            tonumber(
                navigation.heading
            ) or 0

        --------------------------------------------------
        -- READ TARGET BEARING
        --------------------------------------------------

        local bearing =
            tonumber(
                navigation.bearing
            )

        --------------------------------------------------
        -- YAW ERROR
        --------------------------------------------------

        local yawError =
            tonumber(
                navigation.relativeAngle
            ) or 0

        --------------------------------------------------
        -- Prefer bearing-heading when both values
        -- are available.
        --------------------------------------------------

        if bearing ~= nil then

            yawError =
                normalizeAngle(
                    bearing - heading
                )

        end

        yawError =
            normalizeAngle(
                yawError
            )

        state.guidance.yawError =
            yawError

        --------------------------------------------------
        -- PITCH
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
                        distance * distance
                        -
                        verticalOffset *
                        verticalOffset,
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
        -- CURRENT PITCH
        --------------------------------------------------

        local currentPitch =
            tonumber(
                navigation.pitch
            ) or 0

        --------------------------------------------------
        -- PITCH ERROR
        --------------------------------------------------

        local pitchError =
            normalizeAngle(
                desiredPitch -
                currentPitch
            )

        state.guidance.pitchError =
            pitchError

        --------------------------------------------------
        -- TARGET COMMAND Y
        --------------------------------------------------

        local targetCommandY =
            0

        if math.abs(yawError) >
            YAW_DEADZONE then

            targetCommandY =
                yawError *
                YAW_GAIN

        end

        --------------------------------------------------
        -- TARGET COMMAND X
        --------------------------------------------------

        local targetCommandX =
            0

        if math.abs(pitchError) >
            PITCH_DEADZONE then

            targetCommandX =
                pitchError *
                PITCH_GAIN

        end

        --------------------------------------------------
        -- LIMIT TARGET COMMANDS
        --------------------------------------------------

        targetCommandX =
            clamp(
                targetCommandX,
                -MAX_VECTOR,
                MAX_VECTOR
            )

        targetCommandY =
            clamp(
                targetCommandY,
                -MAX_VECTOR,
                MAX_VECTOR
            )

        --------------------------------------------------
        -- DO NOT DRIVE ACTUATOR UNLESS GUIDANCE
        -- IS ACTIVE.
        --------------------------------------------------

        if not state.guidance.active then

            targetCommandX =
                0

            targetCommandY =
                0

        end

        --------------------------------------------------
        -- SMOOTH COMMAND X
        --------------------------------------------------

        currentCommandX =
            approach(
                currentCommandX,
                targetCommandX,
                MAX_COMMAND_STEP
            )

        --------------------------------------------------
        -- SMOOTH COMMAND Y
        --------------------------------------------------

        currentCommandY =
            approach(
                currentCommandY,
                targetCommandY,
                MAX_COMMAND_STEP
            )

        --------------------------------------------------
        -- PUBLISH COMMANDS
        --------------------------------------------------

        state.guidance.commandX =
            currentCommandX

        state.guidance.commandY =
            currentCommandY

    end

    --------------------------------------------------
    -- CONTINUOUS LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do

        update()

        sleep(0.05)

    end

    --------------------------------------------------
    -- SAFE SHUTDOWN
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

--------------------------------------------------
-- MODULE EXPORT
--------------------------------------------------

return {
    run = run
}