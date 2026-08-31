-- Missile Guidance System
-- Relative-vector guidance
--
-- The target vector comes from navigation.lua:
--   targetDeltaX
--   targetDeltaY
--   targetDeltaZ
--
-- The controller does NOT use:
--   targetBearing - heading
--
-- Instead it calculates the required horizontal
-- and vertical pointing angles directly from the
-- target vector, then compares them with the
-- current attitude.
--
-- actuator.lua applies:
--   commandX = pitch correction
--   commandY = yaw correction

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- COMMAND LIMITS
--------------------------------------------------

local BOOST_VECTOR = 0.035

local PITCH_OVER_VECTOR = 0.070

local CRUISE_VECTOR = 0.150

local TERMINAL_VECTOR = 0.250


--------------------------------------------------
-- START
--------------------------------------------------

local START_NEUTRAL_TIME = 1.5

local START_RAMP_TIME = 2.0


--------------------------------------------------
-- PID
--------------------------------------------------

local YAW_KP = 0.08
local PITCH_KP = 0.10

local YAW_KD = 0.10
local PITCH_KD = 0.10

local YAW_KI = 0.0002
local PITCH_KI = 0.0002


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

local MAX_COMMAND_STEP = 0.006


--------------------------------------------------
-- MATH
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
            2 * math.pi

    end


    while angle < -math.pi do

        angle =
            angle +
            2 * math.pi

    end


    return angle
end


--------------------------------------------------
-- APPROACH
--------------------------------------------------

local function approach(
    current,
    target,
    step
)

    local delta =
        target - current


    if delta > step then

        return current + step

    end


    if delta < -step then

        return current - step

    end


    return target
end


--------------------------------------------------
-- MAIN MODULE
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


    --------------------------------------------------
    -- ERRORS
    --------------------------------------------------

    state.guidance.yawError =
        0


    state.guidance.pitchError =
        0


    state.guidance.yawRate =
        0


    state.guidance.pitchRate =
        0


    --------------------------------------------------
    -- PID DEBUG
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


    --------------------------------------------------
    -- TARGET DEBUG
    --------------------------------------------------

    state.guidance.targetBearing =
        0


    state.guidance.targetElevation =
        0


    state.guidance.targetDX =
        0


    state.guidance.targetDY =
        0


    state.guidance.targetDZ =
        0


    --------------------------------------------------
    -- FLIGHT
    --------------------------------------------------

    state.guidance.flightPhase =
        "READY"


    state.guidance.flightTime =
        0


    state.guidance.phaseTime =
        0


    state.guidance.flightMaxVector =
        0


    --------------------------------------------------
    -- PID INTERNAL STATE
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
        -- CONTROL
        --------------------------------------------------

        local control =
            state.system.controlEnabled
            == true


        if not control then

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

        local target =
            state.target


        if type(target) ~= "table"
            or
            target.set ~= true then

            state.guidance.active =
                false


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
        -- FLIGHT
        --------------------------------------------------

        local flight =
            state.flight


        local phase =
            "READY"


        local phaseTime =
            0


        local flightTime =
            0


        if type(flight) == "table" then

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
        -- START STABILIZATION
        --------------------------------------------------

        if phase == "BOOST"
            and
            phaseTime <
            START_NEUTRAL_TIME then

            state.guidance.active =
                true


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


        state.guidance.targetDX =
            dx


        state.guidance.targetDY =
            dy


        state.guidance.targetDZ =
            dz


        --------------------------------------------------
        -- DISTANCE
        --------------------------------------------------

        local distance =
            math.sqrt(
                dx * dx +
                dy * dy +
                dz * dz
            )


        state.guidance.distance =
            distance


        --------------------------------------------------
        -- ARRIVAL
        --------------------------------------------------

        if distance <=
            ARRIVAL_DISTANCE then

            state.guidance.active =
                false


            state.guidance.status =
                "TARGET REACHED"


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
        -- HORIZONTAL DISTANCE
        --------------------------------------------------

        local horizontalDistance =
            math.sqrt(
                dx * dx +
                dz * dz
            )


        --------------------------------------------------
        -- DESIRED YAW
        --------------------------------------------------
        --
        -- World-space target direction:
        --
        -- +Z = 0
        -- +X = +90 degrees
        -- -X = -90 degrees
        -- -Z = 180 degrees
        --------------------------------------------------

        local desiredYaw =
            0


        if horizontalDistance >
            0.001 then

            desiredYaw =
                math.atan(
                    dx,
                    dz
                )

        end


        state.guidance.targetBearing =
            desiredYaw


        --------------------------------------------------
        -- DESIRED PITCH
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

        elseif math.abs(dy) >
            0.001 then

            if dy > 0 then

                desiredPitch =
                    math.pi / 2

            else

                desiredPitch =
                    -math.pi / 2

            end

        end


        state.guidance.targetElevation =
            desiredPitch


        --------------------------------------------------
        -- CURRENT ATTITUDE
        --------------------------------------------------

        local currentYaw =
            tonumber(
                navigation.heading
            )
            or
            0


        local currentPitch =
            tonumber(
                navigation.pitch
            )
            or
            0


        --------------------------------------------------
        -- ANGLE ERRORS
        --------------------------------------------------

        local yawError =
            normalizeAngle(
                desiredYaw -
                currentYaw
            )


        local pitchError =
            normalizeAngle(
                desiredPitch -
                currentPitch
            )


        state.guidance.yawError =
            yawError


        state.guidance.pitchError =
            pitchError


        --------------------------------------------------
        -- ANGULAR VELOCITY
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
        -- TIME STEP
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
        -- INTEGRAL
        --------------------------------------------------

        if math.abs(yawError) >
            YAW_DEADZONE then

            yawIntegral =
                yawIntegral +
                yawError * dt

        else

            yawIntegral =
                yawIntegral *
                0.90

        end


        if math.abs(pitchError) >
            PITCH_DEADZONE then

            pitchIntegral =
                pitchIntegral +
                pitchError * dt

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
        -- P TERMS
        --------------------------------------------------

        local yawP =
            YAW_KP *
            yawError


        local pitchP =
            PITCH_KP *
            pitchError


        --------------------------------------------------
        -- I TERMS
        --------------------------------------------------

        local yawI =
            YAW_KI *
            yawIntegral


        local pitchI =
            PITCH_KI *
            pitchIntegral


        --------------------------------------------------
        -- DAMPING
        --------------------------------------------------

        local yawD =
            -YAW_KD *
            yawRate


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
        -- PHASE LIMIT
        --------------------------------------------------

        local phaseLimit =
            0


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
        -- START RAMP
        --------------------------------------------------

        if phase == "BOOST" then

            local rampTime =
                phaseTime -
                START_NEUTRAL_TIME


            if rampTime < 0 then

                rampTime =
                    0

            end


            local ramp =
                clamp(
                    rampTime /
                    START_RAMP_TIME,
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
        -- SMOOTH COMMAND
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


        state.guidance.active =
            true


        state.guidance.status =
            "GUIDANCE ACTIVE"

    end


    --------------------------------------------------
    -- LOOP
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