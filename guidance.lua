-- Missile Guidance System
-- Uses the custom navigation solution:
--   state.navigation.position
--   state.navigation.targetDeltaX/Y/Z
--   state.navigation.distance
--   state.navigation.bearing
--   state.navigation.heading
--   state.navigation.pitch
--
-- SAFE:
-- Guidance only calculates commands.
-- actuator.lua decides whether commands are actually applied.

--------------------------------------------------
-- LIMITS
--------------------------------------------------

local MAX_VECTOR = 0.25

local YAW_GAIN = 0.15
local PITCH_GAIN = 0.20

local YAW_DEADZONE = math.rad(1.0)
local PITCH_DEADZONE = math.rad(1.0)

local MAX_COMMAND_STEP = 0.025

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- CLAMP
--------------------------------------------------

local function clamp(
    value,
    minimum,
    maximum
)

    value = tonumber(value) or 0

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end


--------------------------------------------------
-- ANGLE NORMALIZATION
--------------------------------------------------

local function normalizeAngle(angle)

    angle = tonumber(angle) or 0

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
-- SMOOTH APPROACH
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
-- MAIN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- STATE
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


    state.guidance.targetBearing =
        0

    state.guidance.targetElevation =
        0


    --------------------------------------------------
    -- INTERNAL COMMAND STATE
    --------------------------------------------------

    local currentCommandX =
        0

    local currentCommandY =
        0


    --------------------------------------------------
    -- UPDATE
    --------------------------------------------------

    local function update()

        --------------------------------------------------
        -- NAVIGATION
        --------------------------------------------------

        local navigation =
            state.navigation


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
        -- ONLINE
        --------------------------------------------------

        state.guidance.online =
            true

        state.guidance.status =
            "ONLINE"


        --------------------------------------------------
        -- TARGET
        --------------------------------------------------

        local targetSet =
            type(state.target) == "table"
            and state.target.set == true


        local navigationTarget =
            navigation.hasNavTarget == true


        state.guidance.active =
            targetSet
            or navigationTarget


        if not state.guidance.active then

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
        -- TARGET VECTOR
        --------------------------------------------------

        local dx =
            tonumber(
                navigation.targetDeltaX
            ) or 0


        local dy =
            tonumber(
                navigation.targetDeltaY
            ) or 0


        local dz =
            tonumber(
                navigation.targetDeltaZ
            ) or 0


        local horizontalDistance =
            math.sqrt(
                dx * dx +
                dz * dz
            )


        local distance =
            tonumber(
                navigation.distance
            ) or 0


        --------------------------------------------------
        -- TARGET BEARING
        --------------------------------------------------

        local targetBearing


        if horizontalDistance >
            0.001 then

            targetBearing =
                math.atan(
                    dx,
                    dz
                )

        else

            targetBearing =
                tonumber(
                    navigation.heading
                ) or 0

        end


        state.guidance.targetBearing =
            targetBearing


        --------------------------------------------------
        -- CURRENT HEADING
        --------------------------------------------------

        local currentHeading =
            tonumber(
                navigation.heading
            ) or 0


        --------------------------------------------------
        -- YAW ERROR
        --------------------------------------------------

        local yawError =
            normalizeAngle(
                targetBearing -
                currentHeading
            )


        state.guidance.yawError =
            yawError


        --------------------------------------------------
        -- TARGET ELEVATION
        --------------------------------------------------

        local desiredPitch =
            0


        if distance >
            0.001 then

            desiredPitch =
                math.atan(
                    dy,
                    math.max(
                        horizontalDistance,
                        0.001
                    )
                )

        end


        state.guidance.targetElevation =
            desiredPitch


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
        -- YAW COMMAND
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
        -- PITCH COMMAND
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
        -- LIMIT
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
        -- SMOOTHING
        --------------------------------------------------

        currentCommandX =
            approach(
                currentCommandX,
                targetCommandX,
                MAX_COMMAND_STEP
            )


        currentCommandY =
            approach(
                currentCommandY,
                targetCommandY,
                MAX_COMMAND_STEP
            )


        --------------------------------------------------
        -- PUBLISH
        --------------------------------------------------

        state.guidance.commandX =
            currentCommandX


        state.guidance.commandY =
            currentCommandY

    end


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do

        update()

        sleep(
            UPDATE_INTERVAL
        )

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