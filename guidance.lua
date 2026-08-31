-- Missile Guidance System
-- CC:Tweaked
--
-- STABILIZED FLIGHT VERSION
--
-- Current rocket geometry:
--
--   commandX -> yaw
--   commandY -> pitch
--
-- Current calibrated rate mapping:
--
--   yawRate   -> navigation.angularRateZ
--   pitchRate -> navigation.angularRateX
--
-- This version:
--   * disables integral control
--   * uses stronger rate damping
--   * uses larger phase limits
--   * reduces authority when angular rate becomes large
--   * keeps BOOST vector at zero
--
-- Goal:
--   allow useful steering while preventing runaway rotation.

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local UPDATE_INTERVAL =
    0.05


--------------------------------------------------
-- START
--------------------------------------------------

local START_NEUTRAL_TIME =
    1.5


local START_RAMP_TIME =
    3.0


--------------------------------------------------
-- VECTOR LIMITS
--
-- These are the limits we actually want.
-- flight.lua is also updated to publish the same values.
--------------------------------------------------

local BOOST_VECTOR =
    0.0


local PITCH_OVER_VECTOR =
    0.050


local CRUISE_VECTOR =
    0.100


local TERMINAL_VECTOR =
    0.250


--------------------------------------------------
-- PID
--------------------------------------------------

local YAW_KP =
    0.025


local PITCH_KP =
    0.030


local YAW_KD =
    0.065


local PITCH_KD =
    0.075


--------------------------------------------------
-- INTEGRAL
--
-- Disabled during stabilization testing.
--------------------------------------------------

local YAW_KI =
    0.0


local PITCH_KI =
    0.0


--------------------------------------------------
-- DEADZONE
--------------------------------------------------

local YAW_DEADZONE =
    math.rad(0.5)


local PITCH_DEADZONE =
    math.rad(0.5)


--------------------------------------------------
-- RATE PROTECTION
--
-- Above these angular rates the controller
-- progressively reduces steering authority.
--
-- Rates are radians/sec.
--------------------------------------------------

local YAW_RATE_SOFT_LIMIT =
    math.rad(2.0)


local YAW_RATE_HARD_LIMIT =
    math.rad(8.0)


local PITCH_RATE_SOFT_LIMIT =
    math.rad(2.0)


local PITCH_RATE_HARD_LIMIT =
    math.rad(8.0)


--------------------------------------------------
-- OUTPUT SLEW
--------------------------------------------------

local MAX_COMMAND_STEP =
    0.0015


--------------------------------------------------
-- ARRIVAL
--------------------------------------------------

local ARRIVAL_DISTANCE =
    5.0


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
        or
        0


    if value < minimum then
        return minimum
    end


    if value > maximum then
        return maximum
    end


    return value

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
-- NORMALIZE ANGLE
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
-- RATE AUTHORITY
--------------------------------------------------

local function rateAuthority(
    rate,
    softLimit,
    hardLimit
)

    local magnitude =
        math.abs(
            tonumber(rate)
            or
            0
        )


    --------------------------------------------------
    -- Normal control
    --------------------------------------------------

    if magnitude <=
        softLimit then

        return 1.0

    end


    --------------------------------------------------
    -- Above hard limit:
    -- no new steering authority
    --------------------------------------------------

    if magnitude >=
        hardLimit then

        return 0.0

    end


    --------------------------------------------------
    -- Linear reduction
    --------------------------------------------------

    return
        1.0 -
        (
            (
                magnitude -
                softLimit
            )
            /
            (
                hardLimit -
                softLimit
            )
        )

end


--------------------------------------------------
-- RESET
--------------------------------------------------

local function resetOutput(
    state,
    currentX,
    currentY
)

    currentX =
        approach(
            currentX,
            0,
            MAX_COMMAND_STEP
        )


    currentY =
        approach(
            currentY,
            0,
            MAX_COMMAND_STEP
        )


    state.guidance.commandX =
        currentX


    state.guidance.commandY =
        currentY


    return
        currentX,
        currentY

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(
    state
)

    state.guidance =
        state.guidance
        or
        {}


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

    g.targetDX = 0
    g.targetDY = 0
    g.targetDZ = 0

    g.distance = 0

    g.flightPhase = "READY"
    g.flightTime = 0
    g.phaseTime = 0
    g.flightMaxVector = 0

    g.rateAuthorityYaw = 1
    g.rateAuthorityPitch = 1


    --------------------------------------------------
    -- INTERNAL
    --------------------------------------------------

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
        -- NAVIGATION
        --------------------------------------------------

        if type(n) ~= "table"
            or
            n.navigationTable ~= true then

            g.status =
                "NAV OFFLINE"


            g.active =
                false


            currentCommandX,
            currentCommandY =
                resetOutput(
                    state,
                    currentCommandX,
                    currentCommandY
                )


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

            g.status =
                "NO TARGET"


            g.active =
                false


            g.distance =
                0


            g.yawError =
                0


            g.pitchError =
                0


            currentCommandX,
            currentCommandY =
                resetOutput(
                    state,
                    currentCommandX,
                    currentCommandY
                )


            return

        end


        --------------------------------------------------
        -- POSITION
        --------------------------------------------------

        local position =
            n.position
            or
            {}


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
        -- TARGET
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
        -- TELEMETRY
        --------------------------------------------------

        g.targetDX =
            dx


        g.targetDY =
            dy


        g.targetDZ =
            dz


        g.distance =
            distance


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


            currentCommandX,
            currentCommandY =
                resetOutput(
                    state,
                    currentCommandX,
                    currentCommandY
                )


            return

        end


        --------------------------------------------------
        -- FORWARD
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


            currentCommandX,
            currentCommandY =
                resetOutput(
                    state,
                    currentCommandX,
                    currentCommandY
                )


            return

        end


        --------------------------------------------------
        -- NORMALIZE
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
        -- HORIZONTAL COMPONENTS
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
        -- PITCH
        --------------------------------------------------

        local currentPitch =
            math.atan(
                fy,
                forwardHorizontal
            )


        local targetPitch =
            math.atan(
                uy,
                targetHorizontal
            )


        local pitchError =
            normalizeAngle(
                targetPitch -
                currentPitch
            )


        --------------------------------------------------
        -- SAVE ERROR
        --------------------------------------------------

        g.yawError =
            yawError


        g.pitchError =
            pitchError


        --------------------------------------------------
        -- ANGULAR RATES
        --
        -- Calibrated mapping:
        --
        -- X vector -> mainly Z rate
        -- Y vector -> mainly X rate
        --------------------------------------------------

        local yawRate =
            tonumber(
                n.angularRateZ
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
        -- RATE AUTHORITY
        --------------------------------------------------

        local yawAuthority =
            rateAuthority(
                yawRate,
                YAW_RATE_SOFT_LIMIT,
                YAW_RATE_HARD_LIMIT
            )


        local pitchAuthority =
            rateAuthority(
                pitchRate,
                PITCH_RATE_SOFT_LIMIT,
                PITCH_RATE_HARD_LIMIT
            )


        g.rateAuthorityYaw =
            yawAuthority


        g.rateAuthorityPitch =
            pitchAuthority


        --------------------------------------------------
        -- PHASE LIMIT
        --
        -- Flight module publishes the official value.
        -- We also protect it locally.
        --------------------------------------------------

        local phaseLimit =
            tonumber(
                g.flightMaxVector
            )
            or
            0


        if phase ==
            "BOOST" then

            phaseLimit =
                math.min(
                    phaseLimit,
                    BOOST_VECTOR
                )


        elseif phase ==
            "PITCH OVER" then

            phaseLimit =
                math.min(
                    phaseLimit,
                    PITCH_OVER_VECTOR
                )


        elseif phase ==
            "CRUISE" then

            phaseLimit =
                math.min(
                    phaseLimit,
                    CRUISE_VECTOR
                )


        elseif phase ==
            "TERMINAL" then

            phaseLimit =
                math.min(
                    phaseLimit,
                    TERMINAL_VECTOR
                )


        else

            phaseLimit =
                0

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


            currentCommandX,
            currentCommandY =
                resetOutput(
                    state,
                    currentCommandX,
                    currentCommandY
                )


            return

        end


        --------------------------------------------------
        -- ACTIVE
        --------------------------------------------------

        g.status =
            "GUIDANCE ACTIVE"


        g.active =
            true


        --------------------------------------------------
        -- BOOST
        --------------------------------------------------

        if phase ==
            "BOOST" then

            g.status =
                "BOOST"


            currentCommandX,
            currentCommandY =
                resetOutput(
                    state,
                    currentCommandX,
                    currentCommandY
                )


            return

        end


        --------------------------------------------------
        -- PITCH OVER RAMP
        --------------------------------------------------

        local controlScale =
            1.0


        if phase ==
            "PITCH OVER" then

            local ramp =
                clamp(
                    phaseTime /
                    START_RAMP_TIME,
                    0,
                    1
                )


            controlScale =
                0.20 +
                (
                    0.80 *
                    ramp
                )

        end


        --------------------------------------------------
        -- PID PROPORTIONAL
        --------------------------------------------------

        local yawP =
            YAW_KP *
            yawError


        local pitchP =
            PITCH_KP *
            pitchError


        --------------------------------------------------
        -- INTEGRAL DISABLED
        --------------------------------------------------

        local yawI =
            0


        local pitchI =
            0


        --------------------------------------------------
        -- RATE DAMPING
        --------------------------------------------------

        local yawD =
            -YAW_KD *
            yawRate


        local pitchD =
            -PITCH_KD *
            pitchRate


        --------------------------------------------------
        -- STORE COMPONENTS
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
            0


        g.pitchIntegral =
            0


        --------------------------------------------------
        -- TOTAL
        --------------------------------------------------

        local yawCommand =
            yawP +
            yawD


        local pitchCommand =
            pitchP +
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
        -- RATE PROTECTION
        --
        -- Do not allow a controller to continue
        -- commanding aggressively while the rocket
        -- is already rotating rapidly.
        --------------------------------------------------

        yawCommand =
            yawCommand *
            yawAuthority


        pitchCommand =
            pitchCommand *
            pitchAuthority


        --------------------------------------------------
        -- PHASE SCALE
        --------------------------------------------------

        yawCommand =
            yawCommand *
            controlScale


        pitchCommand =
            pitchCommand *
            controlScale


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
        -- OUTPUT
        --
        -- X = YAW
        -- Y = PITCH
        --------------------------------------------------

        local requestedX =
            yawCommand


        local requestedY =
            pitchCommand


        --------------------------------------------------
        -- SLEW
        --------------------------------------------------

        currentCommandX =
            approach(
                currentCommandX,
                requestedX,
                MAX_COMMAND_STEP
            )


        currentCommandY =
            approach(
                currentCommandY,
                requestedY,
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
    -- CONTINUOUS LOOP
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