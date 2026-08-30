-- Missile Guidance System
-- PID flight guidance
--
-- Calculates steering commands for the
-- Liquid Vector Thruster.
--
-- actuator.lua is responsible for actually
-- applying these commands to the engine.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

-- Maximum engine gimbal command.
local MAX_VECTOR = 0.25

-- Maximum change of command per update.
local MAX_COMMAND_STEP = 0.025

-- Update interval.
local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- YAW PID
--------------------------------------------------

local YAW_KP = 0.16
local YAW_KI = 0.002
local YAW_KD = 0.08


--------------------------------------------------
-- PITCH PID
--------------------------------------------------

local PITCH_KP = 0.20
local PITCH_KI = 0.002
local PITCH_KD = 0.08


--------------------------------------------------
-- DEADZONE
--------------------------------------------------

local YAW_DEADZONE =
    math.rad(1.0)

local PITCH_DEADZONE =
    math.rad(1.0)


--------------------------------------------------
-- INTEGRAL LIMIT
--------------------------------------------------

local MAX_YAW_INTEGRAL = 1.0
local MAX_PITCH_INTEGRAL = 1.0


--------------------------------------------------
-- TARGET ARRIVAL
--------------------------------------------------

local ARRIVAL_DISTANCE = 5


--------------------------------------------------
-- CLAMP
--------------------------------------------------

local function clamp(
    value,
    minimum,
    maximum
)

    value =
        tonumber(value) or 0


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

    angle =
        tonumber(angle) or 0


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
-- SMOOTH COMMAND
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
    -- CREATE GUIDANCE STATE
    --------------------------------------------------

    state.guidance =
        state.guidance or {}


    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    state.guidance.online =
        false

    state.guidance.status =
        "STARTING"

    state.guidance.active =
        false


    --------------------------------------------------
    -- COMMANDS
    --------------------------------------------------

    state.guidance.commandX =
        0

    state.guidance.commandY =
        0


    --------------------------------------------------
    -- ERRORS
    --------------------------------------------------

    state.guidance.yawError =
        0

    state.guidance.pitchError =
        0


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    state.guidance.targetBearing =
        0

    state.guidance.targetElevation =
        0


    --------------------------------------------------
    -- PID STATE
    --------------------------------------------------

    local yawIntegral =
        0

    local pitchIntegral =
        0


    local previousYawError =
        0

    local previousPitchError =
        0


    --------------------------------------------------
    -- ENGINE COMMAND STATE
    --------------------------------------------------

    local currentCommandX =
        0

    local currentCommandY =
        0


    --------------------------------------------------
    -- TIME
    --------------------------------------------------

    local previousTime =
        os.clock()


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


            yawIntegral =
                0

            pitchIntegral =
                0


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
        -- NAVIGATION STATUS
        --------------------------------------------------

        if not navigation.online then

            state.guidance.online =
                false

            state.guidance.status =
                "NAV OFFLINE"

            state.guidance.active =
                false


            yawIntegral =
                0

            pitchIntegral =
                0


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


        --------------------------------------------------
        -- NO TARGET
        --------------------------------------------------

        if not state.guidance.active then

            yawIntegral =
                0

            pitchIntegral =
                0


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
        -- DISTANCE
        --------------------------------------------------

        local distance =
            tonumber(
                navigation.distance
            ) or 0


        state.guidance.distance =
            distance


        --------------------------------------------------
        -- ARRIVAL
        --------------------------------------------------

        if distance <=
            ARRIVAL_DISTANCE then

            state.guidance.status =
                "TARGET REACHED"

            state.guidance.active =
                false


            yawIntegral =
                0

            pitchIntegral =
                0


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


        --------------------------------------------------
        -- HORIZONTAL DISTANCE
        --------------------------------------------------

        local horizontalDistance =
            math.sqrt(
                dx * dx +
                dz * dz
            )


        --------------------------------------------------
        -- TARGET BEARING
        --------------------------------------------------

        local targetBearing =
            0


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
        -- TIME
        --------------------------------------------------

        local now =
            os.clock()


        local dt =
            now - previousTime


        previousTime =
            now


        --------------------------------------------------
        -- SAFE DT
        --------------------------------------------------

        if dt <= 0
            or dt > 0.5 then

            dt =
                UPDATE_INTERVAL

        end


        --------------------------------------------------
        -- YAW DERIVATIVE
        --------------------------------------------------

        local yawDerivative =
            (
                yawError -
                previousYawError
            ) / dt


        --------------------------------------------------
        -- PITCH DERIVATIVE
        --------------------------------------------------

        local pitchDerivative =
            (
                pitchError -
                previousPitchError
            ) / dt


        --------------------------------------------------
        -- SAVE ERROR
        --------------------------------------------------

        previousYawError =
            yawError


        previousPitchError =
            pitchError


        --------------------------------------------------
        -- YAW INTEGRAL
        --------------------------------------------------

        if math.abs(yawError) >
            YAW_DEADZONE then

            yawIntegral =
                yawIntegral +
                yawError * dt

        else

            yawIntegral =
                yawIntegral * 0.90

        end


        yawIntegral =
            clamp(
                yawIntegral,
                -MAX_YAW_INTEGRAL,
                MAX_YAW_INTEGRAL
            )


        --------------------------------------------------
        -- PITCH INTEGRAL
        --------------------------------------------------

        if math.abs(pitchError) >
            PITCH_DEADZONE then

            pitchIntegral =
                pitchIntegral +
                pitchError * dt

        else

            pitchIntegral =
                pitchIntegral * 0.90

        end


        pitchIntegral =
            clamp(
                pitchIntegral,
                -MAX_PITCH_INTEGRAL,
                MAX_PITCH_INTEGRAL
            )


        --------------------------------------------------
        -- YAW PID
        --------------------------------------------------

        local yawCommand =
            YAW_KP *
            yawError

            +
            YAW_KI *
            yawIntegral

            +
            YAW_KD *
            yawDerivative


        --------------------------------------------------
        -- PITCH PID
        --------------------------------------------------

        local pitchCommand =
            PITCH_KP *
            pitchError

            +
            PITCH_KI *
            pitchIntegral

            +
            PITCH_KD *
            pitchDerivative


        --------------------------------------------------
        -- DEADZONE
        --------------------------------------------------

        if math.abs(yawError) <=
            YAW_DEADZONE then

            yawCommand =
                0

        end


        if math.abs(pitchError) <=
            PITCH_DEADZONE then

            pitchCommand =
                0

        end


        --------------------------------------------------
        -- LIMIT COMMAND
        --------------------------------------------------

        yawCommand =
            clamp(
                yawCommand,
                -MAX_VECTOR,
                MAX_VECTOR
            )


        pitchCommand =
            clamp(
                pitchCommand,
                -MAX_VECTOR,
                MAX_VECTOR
            )


        --------------------------------------------------
        -- COMMAND SMOOTHING
        --------------------------------------------------

        currentCommandY =
            approach(
                currentCommandY,
                yawCommand,
                MAX_COMMAND_STEP
            )


        currentCommandX =
            approach(
                currentCommandX,
                pitchCommand,
                MAX_COMMAND_STEP
            )


        --------------------------------------------------
        -- OUTPUT
        --------------------------------------------------

        state.guidance.commandX =
            currentCommandX


        state.guidance.commandY =
            currentCommandY


        --------------------------------------------------
        -- DEBUG DATA
        --------------------------------------------------

        state.guidance.yawP =
            YAW_KP * yawError

        state.guidance.yawI =
            YAW_KI * yawIntegral

        state.guidance.yawD =
            YAW_KD * yawDerivative


        state.guidance.pitchP =
            PITCH_KP * pitchError

        state.guidance.pitchI =
            PITCH_KI * pitchIntegral

        state.guidance.pitchD =
            PITCH_KD * pitchDerivative


        state.guidance.yawIntegral =
            yawIntegral

        state.guidance.pitchIntegral =
            pitchIntegral


        state.guidance.targetDX =
            dx

        state.guidance.targetDY =
            dy

        state.guidance.targetDZ =
            dz

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


    state.guidance.active =
        false


    state.guidance.online =
        false


    state.guidance.status =
        "OFFLINE"

end


--------------------------------------------------
-- MODULE
--------------------------------------------------

return {
    run = run
}