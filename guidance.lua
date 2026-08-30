-- Missile Guidance System
-- Soft-start stabilized guidance
--
-- CONTROL ON:
--   0.0 - 1.5 s  : engine vector = 0
--   1.5+ s        : soft guidance
--
-- Uses data from navigation.lua.
-- actuator.lua applies commandX / commandY.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

--------------------------------------------------
-- NORMAL GUIDANCE LIMITS
--------------------------------------------------

local MAX_VECTOR = 0.25

local BOOST_VECTOR = 0.035

local PITCH_OVER_VECTOR = 0.07

local CRUISE_VECTOR = 0.15

local TERMINAL_VECTOR = 0.25


--------------------------------------------------
-- SOFT START
--------------------------------------------------

-- Time after CONTROL is enabled during which
-- the engine must remain perfectly neutral.

local START_NEUTRAL_TIME = 1.5


--------------------------------------------------
-- PID
--------------------------------------------------

local YAW_KP = 0.10
local PITCH_KP = 0.12

local YAW_KD = 0.12
local PITCH_KD = 0.12

local YAW_KI = 0.0005
local PITCH_KI = 0.0005


--------------------------------------------------
-- DEADZONE
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
-- COMMAND SLEW
--------------------------------------------------

local MAX_COMMAND_STEP = 0.008


--------------------------------------------------
-- HELPERS
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
        true


    state.guidance.status =
        "ONLINE"


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


    state.guidance.yawRate =
        0


    state.guidance.pitchRate =
        0


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


    state.guidance.flightPhase =
        "READY"


    state.guidance.flightTime =
        0


    state.guidance.phaseTime =
        0


    state.guidance.flightMaxVector =
        0


    --------------------------------------------------
    -- INTERNAL PID STATE
    --------------------------------------------------

    local yawIntegral =
        0


    local pitchIntegral =
        0


    --------------------------------------------------
    -- CURRENT COMMAND
    --------------------------------------------------

    local currentCommandX =
        0


    local currentCommandY =
        0


    --------------------------------------------------
    -- PREVIOUS TIME
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


        if type(navigation) ~=
            "table" then

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

        state.guidance.status =
            "ONLINE"


        --------------------------------------------------
        -- FLIGHT STATE
        --------------------------------------------------

        local flight =
            state.flight


        local phase =
            "READY"


        local phaseTime =
            0


        local flightTime =
            0


        if type(flight) ==
            "table" then

            phase =
                flight.phase
                or
                "READY"


            phaseTime =
                tonumber(
                    flight.phaseElapsed
                )
                or
                0


            flightTime =
                tonumber(
                    flight.elapsed
                )
                or
                0

        end


        state.guidance.flightPhase =
            phase


        state.guidance.phaseTime =
            phaseTime


        state.guidance.flightTime =
            flightTime


        --------------------------------------------------
        -- CONTROL
        --------------------------------------------------

        local controlEnabled =
            state.system.controlEnabled
            == true


        --------------------------------------------------
        -- CONTROL OFF
        --------------------------------------------------

        if not controlEnabled then

            state.guidance.active =
                false


            state.guidance.status =
                "CONTROL OFF"


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


            state.guidance.flightMaxVector =
                0


            return

        end


        --------------------------------------------------
        -- TARGET
        --------------------------------------------------

        local targetSet =
            type(state.target) ==
                "table"
            and
            state.target.set == true


        state.guidance.active =
            targetSet


        --------------------------------------------------
        -- NO TARGET
        --------------------------------------------------

        if not targetSet then

            state.guidance.status =
                "NO TARGET"


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
        -- SOFT START
        --------------------------------------------------
        --
        -- BOOST starts with absolutely zero vector.
        -- This is the most important part for the
        -- current launch problem.
        --------------------------------------------------

        if phase == "BOOST"
            and
            phaseTime <
            START_NEUTRAL_TIME then

            state.guidance.status =
                "START STABILIZE"


            state.guidance.flightMaxVector =
                0


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
            )
            or
            0


        state.guidance.distance =
            distance


        --------------------------------------------------
        -- TARGET REACHED
        --------------------------------------------------

        if distance > 0
            and
            distance <=
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
            )
            or
            0


        local dy =
            tonumber(
                navigation.targetDeltaY
            )
            or
            0


        local dz =
            tonumber(
                navigation.targetDeltaZ
            )
            or
            0


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
            tonumber(
                navigation.bearing
            )
            or
            0


        --------------------------------------------------
        -- CURRENT HEADING
        --------------------------------------------------

        local heading =
            tonumber(
                navigation.heading
            )
            or
            0


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


        state.guidance.targetBearing =
            targetBearing


        --------------------------------------------------
        -- TARGET ELEVATION
        --------------------------------------------------

        local desiredPitch =
            0


        if horizontalDistance >
            0.001 then

            desiredPitch =
                math.atan(
                    dy,
                    horizontalDistance
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
            )
            or
            0


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

        local yawRate =
            tonumber(
                navigation.angularRateY
            )
            or
            0


        local pitchRate =
            tonumber(
                navigation.angularRateX
            )
            or
            0


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
            or
            dt > 0.5 then

            dt =
                UPDATE_INTERVAL

        end


        --------------------------------------------------
        -- PHASE VECTOR LIMIT
        --------------------------------------------------

        local phaseLimit =
            MAX_VECTOR


        if phase == "BOOST" then

            phaseLimit =
                BOOST_VECTOR


        elseif phase ==
            "PITCH OVER" then

            phaseLimit =
                PITCH_OVER_VECTOR


        elseif phase ==
            "CRUISE" then

            phaseLimit =
                CRUISE_VECTOR


        elseif phase ==
            "TERMINAL" then

            phaseLimit =
                TERMINAL_VECTOR


        else

            phaseLimit =
                0

        end


        state.guidance.flightMaxVector =
            phaseLimit


        --------------------------------------------------
        -- INTEGRAL
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


        if math.abs(pitchError) >
            PITCH_DEADZONE then

            pitchIntegral =
                pitchIntegral +
                pitchError * dt

        else

            pitchIntegral =
                pitchIntegral * 0.90

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
        -- PID YAW
        --------------------------------------------------

        local yawP =
            YAW_KP *
            yawError


        local yawI =
            YAW_KI *
            yawIntegral


        local yawD =
            -YAW_KD *
            yawRate


        --------------------------------------------------
        -- PID PITCH
        --------------------------------------------------

        local pitchP =
            PITCH_KP *
            pitchError


        local pitchI =
            PITCH_KI *
            pitchIntegral


        local pitchD =
            -PITCH_KD *
            pitchRate


        --------------------------------------------------
        -- DEBUG
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
        -- TOTAL COMMAND
        --------------------------------------------------

        local yawCommand =
            yawP +
            yawI +
            yawD


        local pitchCommand =
            pitchP +
            pitchI +
            pitchD


        --------------------------------------------------
        -- DEADZONE
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
        -- LIMIT
        --------------------------------------------------

        yawCommand =
            clamp(
                yawCommand,
                -phaseLimit,
                phaseLimit
            )


        pitchCommand =
            clamp(
                pitchCommand,
                -phaseLimit,
                phaseLimit
            )


        --------------------------------------------------
        -- START OF GUIDANCE
        --------------------------------------------------
        --
        -- During the first moments after the
        -- neutral period, smoothly ramp the command.
        --------------------------------------------------

        if phase == "BOOST" then

            local rampTime =
                phaseTime -
                START_NEUTRAL_TIME


            if rampTime < 0 then
                rampTime = 0
            end


            local ramp =
                clamp(
                    rampTime / 2.0,
                    0,
                    1
                )


            yawCommand =
                yawCommand *
                ramp


            pitchCommand =
                pitchCommand *
                ramp

        end


        --------------------------------------------------
        -- SMOOTH OUTPUT
        --------------------------------------------------

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


        --------------------------------------------------
        -- OUTPUT
        --------------------------------------------------

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
        and
        state.system.running do

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
-- EXPORT
--------------------------------------------------

return {
    run = run
}