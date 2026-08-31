-- Missile Guidance System
-- CC:Tweaked
--
-- Manual target:
--   state.target
--
-- Navigation:
--   state.navigation
--
-- CONTROL OFF:
--   telemetry and guidance calculations continue
--   engine commands remain zero
--
-- CONTROL ON:
--   PID steering commands are generated
--
-- IMPORTANT:
-- Navigation Table's internal target is NOT required.
-- Manual target from target.cfg is independent.

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
-- VECTOR LIMITS
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

local YAW_DEADZONE = math.rad(0.5)
local PITCH_DEADZONE = math.rad(0.5)

--------------------------------------------------
-- INTEGRAL LIMIT
--------------------------------------------------

local MAX_YAW_INTEGRAL = 0.5
local MAX_PITCH_INTEGRAL = 0.5

--------------------------------------------------
-- OUTPUT SLEW
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
    minimum,
    maximum
)

    value =
        tonumber(value)
        or 0

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
        tonumber(angle)
        or 0

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
        or {}

    local g =
        state.guidance

    --------------------------------------------------
    -- INITIAL STATE
    --------------------------------------------------

    g.online = true
    g.status = "ONLINE"
    g.active = false

    g.commandX = 0
    g.commandY = 0

    g.yawError = 0
    g.pitchError = 0

    g.yawRate = 0
    g.pitchRate = 0

    g.yawP = 0
    g.yawI = 0
    g.yawD = 0

    g.pitchP = 0
    g.pitchI = 0
    g.pitchD = 0

    g.yawIntegral = 0
    g.pitchIntegral = 0

    g.targetBearing = 0
    g.targetElevation = 0

    g.targetDX = 0
    g.targetDY = 0
    g.targetDZ = 0

    g.distance = 0

    g.flightPhase = "READY"
    g.flightTime = 0
    g.phaseTime = 0

    g.flightMaxVector = 0

    g.boostAltitude = 100
    g.cruiseAltitude = 300
    g.terminalDistance = 500


    --------------------------------------------------
    -- INTERNAL PID STATE
    --------------------------------------------------

    local yawIntegral = 0
    local pitchIntegral = 0

    local currentCommandX = 0
    local currentCommandY = 0

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

            g.status =
                "NAV OFFLINE"

            g.active =
                false

            g.distance =
                0

            g.targetDX =
                0

            g.targetDY =
                0

            g.targetDZ =
                0

            g.yawError =
                0

            g.pitchError =
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


            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY

            return

        end


        --------------------------------------------------
        -- MANUAL TARGET CHECK
        --------------------------------------------------

        local target =
            state.target


        if type(target) ~= "table"
            or
            target.set ~= true then

            g.status =
                "NO TARGET"

            g.active =
                false

            g.distance =
                0

            g.targetDX =
                0

            g.targetDY =
                0

            g.targetDZ =
                0

            g.yawError =
                0

            g.pitchError =
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

            g.commandX =
                currentCommandX

            g.commandY =
                currentCommandY

            return

        end


        --------------------------------------------------
        -- CURRENT POSITION
        --------------------------------------------------

        local position =
            n.position
            or {}


        local px =
            tonumber(
                position.x
            )
            or
            0


        local py =
            tonumber(
                position.y
            )
            or
            0


        local pz =
            tonumber(
                position.z
            )
            or
            0


        --------------------------------------------------
        -- TARGET POSITION
        --------------------------------------------------

        local tx =
            tonumber(
                target.x
            )
            or
            0


        local ty =
            tonumber(
                target.y
            )
            or
            0


        local tz =
            tonumber(
                target.z
            )
            or
            0


        --------------------------------------------------
        -- TARGET VECTOR
        --------------------------------------------------

        local dx =
            tx -
            px


        local dy =
            ty -
            py


        local dz =
            tz -
            pz


        local distance =
            vectorLength(
                dx,
                dy,
                dz
            )


        --------------------------------------------------
        -- SAVE TARGET DATA
        --------------------------------------------------

        g.targetDX =
            dx

        g.targetDY =
            dy

        g.targetDZ =
            dz

        g.distance =
            distance


        --------------------------------------------------
        -- KEEP NAVIGATION TELEMETRY SYNCHRONIZED
        --------------------------------------------------

        n.targetDeltaX =
            dx

        n.targetDeltaY =
            dy

        n.targetDeltaZ =
            dz

        n.targetDistance =
            distance

        n.distance =
            distance


        --------------------------------------------------
        -- FLIGHT DATA
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


        g.flightPhase =
            phase


        g.phaseTime =
            phaseTime


        g.flightTime =
            flightTime


        --------------------------------------------------
        -- TARGET REACHED
        --------------------------------------------------

        if distance <=
            ARRIVAL_DISTANCE then

            g.status =
                "TARGET REACHED"


            g.active =
                false


            g.yawError =
                0


            g.pitchError =
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
            tonumber(
                forward.x
            )
            or
            0


        local fy =
            tonumber(
                forward.y
            )
            or
            0


        local fz =
            tonumber(
                forward.z
            )
            or
            -1


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


            g.active =
                false


            g.yawError =
                0


            g.pitchError =
                0


            g.commandX =
                0


            g.commandY =
                0


            return

        end


        --------------------------------------------------
        -- NORMALIZE FORWARD
        --------------------------------------------------

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

        local targetLength =
            math.max(
                distance,
                0.000001
            )


        local ux =
            dx /
            targetLength


        local uy =
            dy /
            targetLength


        local uz =
            dz /
            targetLength


        --------------------------------------------------
        -- HORIZONTAL
        --------------------------------------------------

        local forwardHorizontal =
            math.sqrt(
                fx * fx +
                fz * fz
            )


        local targetHorizontal =
            math.sqrt(
                ux * ux +
                uz * uz
            )


        --------------------------------------------------
        -- YAW ERROR
        --------------------------------------------------

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
                ux /
                targetHorizontal


            local tpz =
                uz /
                targetHorizontal


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
                uy,
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


        --------------------------------------------------
        -- SAVE GUIDANCE DATA
        --------------------------------------------------

        g.yawError =
            yawError


        g.pitchError =
            pitchError


        g.targetBearing =
            yawError


        g.targetElevation =
            targetPitch


        --------------------------------------------------
        -- ANGULAR RATES
        --------------------------------------------------

        g.yawRate =
            tonumber(
                n.angularRateY
            )
            or
            0


        g.pitchRate =
            tonumber(
                n.angularRateX
            )
            or
            0


        --------------------------------------------------
        -- VECTOR LIMIT
        --------------------------------------------------

        local phaseLimit =
            0


        if phase == "BOOST" then

            phaseLimit =
                BOOST_VECTOR


        elseif phase == "PITCH OVER" then

            phaseLimit =
                PITCH_OVER_VECTOR


        elseif phase == "CRUISE" then

            phaseLimit =
                CRUISE_VECTOR


        elseif phase == "TERMINAL" then

            phaseLimit =
                TERMINAL_VECTOR

        end


        g.flightMaxVector =
            phaseLimit


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
        -- CONTROL OFF
        --------------------------------------------------

        if state.system.controlEnabled
            ~= true then

            g.status =
                "CONTROL OFF"


            g.active =
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


            g.commandX =
                currentCommandX


            g.commandY =
                currentCommandY


            return

        end


        --------------------------------------------------
        -- CONTROL ACTIVE
        --------------------------------------------------

        g.status =
            "GUIDANCE ACTIVE"


        g.active =
            true


        --------------------------------------------------
        -- START NEUTRAL
        --------------------------------------------------

        if phase == "BOOST"
            and
            phaseTime <
            START_NEUTRAL_TIME then

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
        -- PID
        --------------------------------------------------

        local yawP =
            YAW_KP *
            yawError


        local yawI =
            YAW_KI *
            yawIntegral


        local yawD =
            -YAW_KD *
            g.yawRate


        local pitchP =
            PITCH_KP *
            pitchError


        local pitchI =
            PITCH_KI *
            pitchIntegral


        local pitchD =
            -PITCH_KD *
            g.pitchRate


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


        --------------------------------------------------
        -- COMMAND
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
        -- BOOST RAMP
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

        g.commandX =
            currentCommandX


        g.commandY =
            currentCommandY

    end


    --------------------------------------------------
    -- CONTINUOUS GUIDANCE LOOP
    --
    -- THIS WAS MISSING IN THE REPOSITORY VERSION.
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
    -- SHUTDOWN
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