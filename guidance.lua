-- Missile Guidance System
-- Relative forward-vector guidance
--
-- Uses:
--   navigation.forward
--   navigation.targetDeltaX/Y/Z
--   navigation.angularRateX/Y
--
-- Outputs:
--   guidance.commandX
--   guidance.commandY
--
-- actuator.lua sends these commands to all engines.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- START STABILIZATION
--------------------------------------------------

local START_NEUTRAL_TIME = 1.5
local START_RAMP_TIME = 2.0


--------------------------------------------------
-- COMMAND LIMITS
--------------------------------------------------

local BOOST_VECTOR = 0.035
local PITCH_OVER_VECTOR = 0.070
local CRUISE_VECTOR = 0.150
local TERMINAL_VECTOR = 0.250


--------------------------------------------------
-- PID
--------------------------------------------------

local YAW_KP = 0.10
local PITCH_KP = 0.12

local YAW_KD = 0.12
local PITCH_KD = 0.12

local YAW_KI = 0.00015
local PITCH_KI = 0.00015


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
-- COMMAND SLEW
--------------------------------------------------

local MAX_COMMAND_STEP = 0.004


--------------------------------------------------
-- ARRIVAL
--------------------------------------------------

local ARRIVAL_DISTANCE = 5


--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function clamp(
    value,
    minValue,
    maxValue
)

    value =
        tonumber(value)
        or
        0


    if value < minValue then
        return minValue
    end


    if value > maxValue then
        return maxValue
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
        tonumber(angle)
        or
        0


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
-- APPROACH
--------------------------------------------------

local function approach(
    current,
    target,
    step
)

    local delta =
        target -
        current


    if delta > step then
        return current + step
    end


    if delta < -step then
        return current - step
    end


    return target

end


--------------------------------------------------
-- VECTOR LENGTH
--------------------------------------------------

local function vectorLength(
    x,
    y,
    z
)

    return math.sqrt(
        x * x +
        y * y +
        z * z
    )

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    state.guidance =
        state.guidance
        or
        {}


    local g =
        state.guidance


    g.online =
        true


    g.status =
        "ONLINE"


    g.active =
        false


    g.commandX =
        0


    g.commandY =
        0


    g.yawError =
        0


    g.pitchError =
        0


    g.yawRate =
        0


    g.pitchRate =
        0


    g.yawP =
        0

    g.yawI =
        0

    g.yawD =
        0


    g.pitchP =
        0

    g.pitchI =
        0

    g.pitchD =
        0


    g.yawIntegral =
        0

    g.pitchIntegral =
        0


    g.targetBearing =
        0

    g.targetElevation =
        0


    g.distance =
        0


    g.flightPhase =
        "READY"

    g.flightTime =
        0

    g.phaseTime =
        0


    g.flightMaxVector =
        0


    g.boostAltitude =
        100

    g.cruiseAltitude =
        300

    g.terminalDistance =
        500


    --------------------------------------------------
    -- INTERNAL STATE
    --------------------------------------------------

    local yawIntegral =
        0

    local pitchIntegral =
        0


    local currentCommandX =
        0

    local currentCommandY =
        0


    local previousTime =
        os.clock()


    --------------------------------------------------
    -- UPDATE
    --------------------------------------------------

    local function update()

        local n =
            state.navigation


        --------------------------------------------------
        -- NAVIGATION CHECK
        --------------------------------------------------

        if type(n) ~= "table"
            or
            n.navigationTable ~= true then

            g.active =
                false


            g.status =
                "NAV OFFLINE"


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


            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY


            return

        end


        --------------------------------------------------
        -- TARGET CHECK
        --------------------------------------------------

        if type(state.target) ~= "table"
            or
            state.target.set ~= true
            or
            n.hasNavTarget ~= true then

            g.active =
                false


            g.status =
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


            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY


            return

        end


        --------------------------------------------------
        -- CONTROL CHECK
        --------------------------------------------------

        if state.system.controlEnabled ~= true then

            g.active =
                false


            g.status =
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


            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY


            g.flightMaxVector =
                0


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


        g.flightPhase =
            phase


        g.phaseTime =
            phaseTime


        g.flightTime =
            flightTime


        --------------------------------------------------
        -- DISTANCE
        --------------------------------------------------

        local dx =
            tonumber(
                n.targetDeltaX
            )
            or
            0


        local dy =
            tonumber(
                n.targetDeltaY
            )
            or
            0


        local dz =
            tonumber(
                n.targetDeltaZ
            )
            or
            0


        local distance =
            vectorLength(
                dx,
                dy,
                dz
            )


        g.distance =
            distance


        g.targetDX =
            dx

        g.targetDY =
            dy

        g.targetDZ =
            dz


        --------------------------------------------------
        -- ARRIVAL
        --------------------------------------------------

        if distance <=
            ARRIVAL_DISTANCE then

            g.active =
                false


            g.status =
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


            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY


            return

        end


        --------------------------------------------------
        -- FORWARD VECTOR
        --------------------------------------------------

        local forward =
            n.forward
            or
            {}


        local fx =
            tonumber(forward.x)
            or
            0


        local fy =
            tonumber(forward.y)
            or
            0


        local fz =
            tonumber(forward.z)
            or
            1


        --------------------------------------------------
        -- NORMALIZE FORWARD
        --------------------------------------------------

        local forwardLength =
            vectorLength(
                fx,
                fy,
                fz
            )


        if forwardLength <
            0.000001 then

            g.status =
                "INVALID ATTITUDE"


            g.commandX =
                0

            g.commandY =
                0

            return

        end


        fx =
            fx /
            forwardLength


        fy =
            fy /
            forwardLength


        fz =
            fz /
            forwardLength


        --------------------------------------------------
        -- NORMALIZE TARGET
        --------------------------------------------------

        local tx =
            dx /
            distance


        local ty =
            dy /
            distance


        local tz =
            dz /
            distance


        --------------------------------------------------
        -- CURRENT YAW
        --
        -- Horizontal projection of forward vector.
        --------------------------------------------------

        local forwardHorizontal =
            math.sqrt(
                fx * fx +
                fz * fz
            )


        local targetHorizontal =
            math.sqrt(
                tx * tx +
                tz * tz
            )


        local yawError =
            0


        if forwardHorizontal >
            0.000001
            and
            targetHorizontal >
            0.000001 then


            local fpx =
                fx /
                forwardHorizontal


            local fpz =
                fz /
                forwardHorizontal


            local tpx =
                tx /
                targetHorizontal


            local tpz =
                tz /
                targetHorizontal


            --------------------------------------------------
            -- Signed angle from forward to target.
            --------------------------------------------------

            local cross =
                fpx * tpz -
                fpz * tpx


            local dot =
                fpx * tpx +
                fpz * tpz


            dot =
                clamp(
                    dot,
                    -1,
                    1
                )


            yawError =
                math.atan(
                    cross,
                    dot
                )

        end


        --------------------------------------------------
        -- CURRENT PITCH
        --------------------------------------------------

        local currentPitch =
            math.atan(
                fy,
                forwardHorizontal
            )


        --------------------------------------------------
        -- TARGET PITCH
        --------------------------------------------------

        local targetPitch =
            math.atan(
                ty,
                targetHorizontal
            )


        --------------------------------------------------
        -- PITCH ERROR
        --------------------------------------------------

        local pitchError =
            normalizeAngle(
                targetPitch -
                currentPitch
            )


        g.yawError =
            yawError


        g.pitchError =
            pitchError


        g.targetBearing =
            yawError


        g.targetElevation =
            targetPitch


        --------------------------------------------------
        -- RATES
        --------------------------------------------------

        local yawRate =
            tonumber(
                n.angularRateY
            )
            or
            0


        local pitchRate =
            tonumber(
                n.angularRateX
            )
            or
            0


        g.yawRate =
            yawRate


        g.pitchRate =
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
        -- VECTOR LIMIT
        --------------------------------------------------

        local limit =
            0


        if phase == "BOOST" then

            limit =
                BOOST_VECTOR


        elseif phase ==
            "PITCH OVER" then

            limit =
                PITCH_OVER_VECTOR


        elseif phase ==
            "CRUISE" then

            limit =
                CRUISE_VECTOR


        elseif phase ==
            "TERMINAL" then

            limit =
                TERMINAL_VECTOR

        end


        g.flightMaxVector =
            limit


        --------------------------------------------------
        -- START NEUTRAL
        --------------------------------------------------

        if phase == "BOOST"
            and
            phaseTime <
            START_NEUTRAL_TIME then

            g.active =
                true


            g.status =
                "START STABILIZE"


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


            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY


            return

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
        -- P
        --------------------------------------------------

        local yawP =
            YAW_KP *
            yawError


        local pitchP =
            PITCH_KP *
            pitchError


        --------------------------------------------------
        -- I
        --------------------------------------------------

        local yawI =
            YAW_KI *
            yawIntegral


        local pitchI =
            PITCH_KI *
            pitchIntegral


        --------------------------------------------------
        -- D
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

        g.yawP =
            yawP

        g.yawI =
            yawI

        g.yawD =
            yawD


        g.pitchP =
            pitchP

        g.pitchI =
            pitchI

        g.pitchD =
            pitchD


        g.yawIntegral =
            yawIntegral

        g.pitchIntegral =
            pitchIntegral


        --------------------------------------------------
        -- TOTAL
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
        -- START RAMP
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
                -limit,
                limit
            )


        pitchCommand =
            clamp(
                pitchCommand,
                -limit,
                limit
            )


        --------------------------------------------------
        -- SMOOTH OUTPUT
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

        g.commandX =
            currentCommandX


        g.commandY =
            currentCommandY


        g.active =
            true


        g.status =
            "GUIDANCE ACTIVE"

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

    g.commandX =
        0

    g.commandY =
        0

    g.active =
        false

    g.online =
        false

    g.status =
        "OFFLINE"

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}