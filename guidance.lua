-- Missile Guidance System
-- Stabilized PID guidance controller
--
-- Uses:
--   Navigation Table
--   Gimbal Sensor
--   Velocity Sensor
--   Custom navigation solution
--
-- Main purpose:
--   1. Point missile toward target
--   2. Dampen unwanted rotation
--   3. Prevent uncontrolled spinning
--
-- actuator.lua applies the actual commands.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local MAX_VECTOR = 0.25

local MAX_COMMAND_STEP = 0.02

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- PROPORTIONAL GAINS
--------------------------------------------------

local YAW_KP = 0.10

local PITCH_KP = 0.12


--------------------------------------------------
-- DERIVATIVE / DAMPING GAINS
--------------------------------------------------

-- These values counteract angular velocity.

local YAW_KD = 0.12

local PITCH_KD = 0.12


--------------------------------------------------
-- INTEGRAL
--------------------------------------------------

-- Keep integral very small.
-- Large integral values can cause oscillation.

local YAW_KI = 0.0005

local PITCH_KI = 0.0005


--------------------------------------------------
-- DEAD ZONES
--------------------------------------------------

local YAW_DEADZONE =
    math.rad(0.5)

local PITCH_DEADZONE =
    math.rad(0.5)


--------------------------------------------------
-- INTEGRAL LIMIT
--------------------------------------------------

local MAX_YAW_INTEGRAL = 0.5

local MAX_PITCH_INTEGRAL = 0.5


--------------------------------------------------
-- ARRIVAL
--------------------------------------------------

local ARRIVAL_DISTANCE = 5


--------------------------------------------------
-- ANGULAR RATE LIMIT
--------------------------------------------------

-- If the missile is rotating faster than this,
-- stabilization becomes more aggressive.

local MAX_RATE =
    math.rad(180)


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
-- NORMALIZE ANGLE
--------------------------------------------------

local function normalizeAngle(
    angle
)

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
-- MAIN MODULE
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- INITIALIZE
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
    -- DEBUG VALUES
    --------------------------------------------------

    state.guidance.yawP =
        0

    state.guidance.yawI =
        0

    state.guidance.yawD =
        0


    state.guidance.pitchP =
        0

    state.guidance.pitchI =
        0

    state.guidance.pitchD =
        0


    state.guidance.yawRate =
        0

    state.guidance.pitchRate =
        0


    --------------------------------------------------
    -- PID STATE
    --------------------------------------------------

    local yawIntegral =
        0


    local pitchIntegral =
        0


    --------------------------------------------------
    -- COMMAND STATE
    --------------------------------------------------

    local currentCommandX =
        0


    local currentCommandY =
        0


    --------------------------------------------------
    -- TIMER
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


            state.guidance.yawP =
                0

            state.guidance.yawI =
                0

            state.guidance.yawD =
                0


            state.guidance.pitchP =
                0

            state.guidance.pitchI =
                0

            state.guidance.pitchD =
                0


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
        -- TARGET REACHED
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

        local heading =
            tonumber(
                navigation.heading
            ) or 0


        --------------------------------------------------
        -- YAW ERROR
        --------------------------------------------------

        local yawError =
            normalizeAngle(
                targetBearing -
                heading
            )


        state.guidance.yawError =
            yawError


        --------------------------------------------------
        -- TARGET PITCH
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
        -- ANGULAR RATES
        --------------------------------------------------
        --
        -- Gimbal Sensor provides angular velocity.
        --
        -- We use it to actively oppose rotation.
        --------------------------------------------------

        local yawRate =
            tonumber(
                navigation.angularRateY
            ) or 0


        local pitchRate =
            tonumber(
                navigation.angularRateX
            ) or 0


        state.guidance.yawRate =
            yawRate


        state.guidance.pitchRate =
            pitchRate


        --------------------------------------------------
        -- TIME
        --------------------------------------------------

        local now =
            os.clock()


        local dt =
            now -
            previousTime


        previousTime =
            now


        if dt <= 0
            or dt > 0.5 then

            dt =
                UPDATE_INTERVAL

        end


        --------------------------------------------------
        -- INTEGRAL
        --------------------------------------------------

        if math.abs(yawError) >
            YAW_DEADZONE then

            yawIntegral =
                yawIntegral +
                yawError *
                dt

        else

            yawIntegral =
                yawIntegral *
                0.90

        end


        if math.abs(pitchError) >
            PITCH_DEADZONE then

            pitchIntegral =
                pitchIntegral +
                pitchError *
                dt

        else

            pitchIntegral =
                pitchIntegral *
                0.90

        end


        yawIntegral =
            clamp(
                yawIntegral,
                -MAX_YAW_INTEGRAL,
                MAX_YAW_INTEGRAL
            )


        pitchIntegral =
            clamp(
                pitchIntegral,
                -MAX_PITCH_INTEGRAL,
                MAX_PITCH_INTEGRAL
            )


        --------------------------------------------------
        -- RATE LIMIT
        --------------------------------------------------

        yawRate =
            clamp(
                yawRate,
                -MAX_RATE,
                MAX_RATE
            )


        pitchRate =
            clamp(
                pitchRate,
                -MAX_RATE,
                MAX_RATE
            )


        --------------------------------------------------
        -- YAW PROPORTIONAL
        --------------------------------------------------

        local yawP =
            YAW_KP *
            yawError


        --------------------------------------------------
        -- YAW INTEGRAL
        --------------------------------------------------

        local yawI =
            YAW_KI *
            yawIntegral


        --------------------------------------------------
        -- YAW DAMPING
        --------------------------------------------------
        --
        -- IMPORTANT:
        -- D term opposes angular velocity.
        --------------------------------------------------

        local yawD =
            -YAW_KD *
            yawRate


        --------------------------------------------------
        -- PITCH PROPORTIONAL
        --------------------------------------------------

        local pitchP =
            PITCH_KP *
            pitchError


        --------------------------------------------------
        -- PITCH INTEGRAL
        --------------------------------------------------

        local pitchI =
            PITCH_KI *
            pitchIntegral


        --------------------------------------------------
        -- PITCH DAMPING
        --------------------------------------------------

        local pitchD =
            -PITCH_KD *
            pitchRate


        --------------------------------------------------
        -- SAVE DEBUG
        --------------------------------------------------

        state.guidance.yawP =
            yawP


        state.guidance.yawI =
            yawI


        state.guidance.yawD =
            yawD


        state.guidance.pitchP =
            pitchP


        state.guidance.pitchI =
            pitchI


        state.guidance.pitchD =
            pitchD


        state.guidance.yawIntegral =
            yawIntegral


        state.guidance.pitchIntegral =
            pitchIntegral


        --------------------------------------------------
        -- TOTAL YAW COMMAND
        --------------------------------------------------

        local yawCommand =
            yawP +
            yawI +
            yawD


        --------------------------------------------------
        -- TOTAL PITCH COMMAND
        --------------------------------------------------

        local pitchCommand =
            pitchP +
            pitchI +
            pitchD


        --------------------------------------------------
        -- DEAD ZONES
        --------------------------------------------------

        if math.abs(yawError) <=
            YAW_DEADZONE then

            yawCommand =
                yawD

        end


        if math.abs(pitchError) <=
            PITCH_DEADZONE then

            pitchCommand =
                pitchD

        end


        --------------------------------------------------
        -- COMMAND LIMIT
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
        -- OUTPUT
        --------------------------------------------------

        -- X = pitch
        -- Y = yaw

        currentCommandX =
            approach(
                currentCommandX,
                pitchCommand,
                MAX_COMMAND_STEP
            )


        currentCommandY =
            approach(
                currentCommandY,
                yawCommand,
                MAX_COMMAND_STEP
            )


        state.guidance.commandX =
            currentCommandX


        state.guidance.commandY =
            currentCommandY


        --------------------------------------------------
        -- DEBUG VECTOR
        --------------------------------------------------

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