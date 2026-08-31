-- Missile Guidance System
-- CC:Tweaked
--
-- GUIDANCE VERSION 5
--
-- Navigation.lua already converts the target vector
-- into the PHYSICAL ROCKET FRAME:
--
--   navigation.localTargetX
--   navigation.localTargetY
--   navigation.localTargetZ
--
-- Therefore guidance does NOT perform another world/body
-- conversion. This avoids double-inverting the Navigation
-- Table orientation.
--
-- Control:
--
--   commandX = YAW
--   commandY = PITCH
--
-- Rate mapping from current calibration:
--
--   yawRate   = angularRateZ
--   pitchRate = angularRateX
--
-- Integral control is disabled.

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- PITCH OVER
--------------------------------------------------

local START_RAMP_TIME = 0.5


--------------------------------------------------
-- VECTOR LIMITS
--------------------------------------------------

local BOOST_LIMIT = 0.000

local PITCH_OVER_LIMIT = 0.100

local CRUISE_LIMIT = 0.150

local TERMINAL_LIMIT = 0.250


--------------------------------------------------
-- PID
--------------------------------------------------

local YAW_KP = 0.025

local PITCH_KP = 0.035

local YAW_KD = 0.060

local PITCH_KD = 0.070


--------------------------------------------------
-- INTEGRAL
--------------------------------------------------

local YAW_KI = 0.0

local PITCH_KI = 0.0


--------------------------------------------------
-- DEADZONE
--------------------------------------------------

local YAW_DEADZONE =
    math.rad(0.5)

local PITCH_DEADZONE =
    math.rad(0.5)


--------------------------------------------------
-- RATE PROTECTION
--------------------------------------------------

local YAW_RATE_SOFT =
    math.rad(8.0)

local YAW_RATE_HARD =
    math.rad(20.0)

local PITCH_RATE_SOFT =
    math.rad(8.0)

local PITCH_RATE_HARD =
    math.rad(20.0)


--------------------------------------------------
-- OUTPUT SLEW
--------------------------------------------------

local MAX_COMMAND_STEP =
    0.0040


--------------------------------------------------
-- ARRIVAL
--------------------------------------------------

local ARRIVAL_DISTANCE =
    5.0


--------------------------------------------------
-- CLAMP
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


    if magnitude <=
        softLimit then

        return 1.0

    end


    if magnitude >=
        hardLimit then

        return 0.15

    end


    local fraction =
        (
            magnitude -
            softLimit
        )
        /
        (
            hardLimit -
            softLimit
        )


    return
        1.0 -
        (
            0.85 *
            fraction
        )

end


--------------------------------------------------
-- RESET OUTPUT
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

    g.targetDX =
        0

    g.targetDY =
        0

    g.targetDZ =
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

    g.rateAuthorityYaw =
        1.0

    g.rateAuthorityPitch =
        1.0


    --------------------------------------------------
    -- INTERNAL OUTPUT
    --------------------------------------------------

    local currentCommandX =
        0

    local currentCommandY =
        0


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
        -- TARGET CHECK
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
            tonumber(position.x)
            or
            0

        local py =
            tonumber(position.y)
            or
            0

        local pz =
            tonumber(position.z)
            or
            0


        --------------------------------------------------
        -- TARGET
        --------------------------------------------------

        local tx =
            tonumber(target.x)
            or
            0

        local ty =
            tonumber(target.y)
            or
            0

        local tz =
            tonumber(target.z)
            or
            0


        --------------------------------------------------
        -- WORLD TARGET VECTOR
        --------------------------------------------------

        local dx =
            tx - px

        local dy =
            ty - py

        local dz =
            tz - pz


        local distance =
            vectorLength(
                dx,
                dy,
                dz
            )


        --------------------------------------------------
        -- SAVE WORLD TARGET
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
        -- IMPORTANT:
        --
        -- navigation.localTargetX/Y/Z are ALREADY in
        -- the physical rocket coordinate frame.
        --
        -- navigation.lua performs:
        --
        -- world -> navigation body
        -- navigation body -> rocket body
        --
        -- so DO NOT invert them again here.
        --------------------------------------------------

        local lx =
            tonumber(
                n.localTargetX
            )
            or
            0


        local ly =
            tonumber(
                n.localTargetY
            )
            or
            0


        local lz =
            tonumber(
                n.localTargetZ
            )
            or
            0


        local localLength =
            vectorLength(
                lx,
                ly,
                lz
            )


        if localLength <
            0.000001 then

            g.status =
                "INVALID TARGET VECTOR"

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
        -- NORMALIZE LOCAL TARGET
        --------------------------------------------------

        lx =
            lx /
            localLength

        ly =
            ly /
            localLength

        lz =
            lz /
            localLength


        --------------------------------------------------
        -- HORIZONTAL COMPONENT
        --------------------------------------------------

        local horizontal =
            math.sqrt(
                lx * lx +
                lz * lz
            )


        --------------------------------------------------
        -- TARGET YAW
        --
        -- Positive X = target to one side.
        --------------------------------------------------

        local yawError =
            math.atan(
                lx,
                lz
            )


        --------------------------------------------------
        -- TARGET PITCH
        --
        -- Positive Y = target above rocket forward axis.
        --------------------------------------------------

        local pitchError =
            math.atan(
                ly,
                horizontal
            )


        yawError =
            normalizeAngle(
                yawError
            )


        pitchError =
            normalizeAngle(
                pitchError
            )


        --------------------------------------------------
        -- SAVE ERRORS
        --------------------------------------------------

        g.yawError =
            yawError

        g.pitchError =
            pitchError


        --------------------------------------------------
        -- ANGULAR RATE
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
                YAW_RATE_SOFT,
                YAW_RATE_HARD
            )


        local pitchAuthority =
            rateAuthority(
                pitchRate,
                PITCH_RATE_SOFT,
                PITCH_RATE_HARD
            )


        g.rateAuthorityYaw =
            yawAuthority

        g.rateAuthorityPitch =
            pitchAuthority


        --------------------------------------------------
        -- PHASE LIMIT
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
                BOOST_LIMIT


        elseif phase ==
            "PITCH_OVER"
            or
            phase ==
            "PITCH OVER" then

            phaseLimit =
                math.min(
                    PITCH_OVER_LIMIT,
                    math.abs(
                        phaseLimit
                    )
                )


        elseif phase ==
            "CRUISE" then

            phaseLimit =
                math.min(
                    CRUISE_LIMIT,
                    math.abs(
                        phaseLimit
                    )
                )


        elseif phase ==
            "TERMINAL" then

            phaseLimit =
                math.min(
                    TERMINAL_LIMIT,
                    math.abs(
                        phaseLimit
                    )
                )


        else

            phaseLimit =
                0

        end


        g.flightMaxVector =
            phaseLimit


        --------------------------------------------------
        -- CONTROL ENABLE
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
            "PITCH_OVER"
            or
            phase ==
            "PITCH OVER" then

            local ramp =
                clamp(
                    phaseTime /
                    START_RAMP_TIME,
                    0,
                    1
                )


            controlScale =
                0.50 +
                (
                    0.50 *
                    ramp
                )

        end


        --------------------------------------------------
        -- DEADZONE
        --------------------------------------------------

        local effectiveYawError =
            yawError


        local effectivePitchError =
            pitchError


        if math.abs(
            effectiveYawError
        ) <=
        YAW_DEADZONE then

            effectiveYawError =
                0

        end


        if math.abs(
            effectivePitchError
        ) <=
        PITCH_DEADZONE then

            effectivePitchError =
                0

        end


        --------------------------------------------------
        -- PROPORTIONAL
        --------------------------------------------------

        local yawP =
            YAW_KP *
            effectiveYawError


        local pitchP =
            PITCH_KP *
            effectivePitchError


        --------------------------------------------------
        -- INTEGRAL
        --
        -- Disabled.
        --------------------------------------------------

        local yawI =
            YAW_KI *
            0


        local pitchI =
            PITCH_KI *
            0


        --------------------------------------------------
        -- DERIVATIVE
        --
        -- Opposes current angular velocity.
        --------------------------------------------------

        local yawD =
            -YAW_KD *
            yawRate


        local pitchD =
            -PITCH_KD *
            pitchRate


        --------------------------------------------------
        -- SAVE PID COMPONENTS
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


        --------------------------------------------------
        -- CONTROLLER
        --------------------------------------------------

        local yawController =
            yawP +
            yawI +
            yawD


        local pitchController =
            pitchP +
            pitchI +
            pitchD


        --------------------------------------------------
        -- PHYSICAL COMMAND
        --
        -- These signs are kept according to the current
        -- bench calibration.
        --------------------------------------------------

        local yawCommand =
            -yawController


        local pitchCommand =
            -pitchController


        --------------------------------------------------
        -- RATE PROTECTION
        --------------------------------------------------

        yawCommand =
            yawCommand *
            yawAuthority


        pitchCommand =
            pitchCommand *
            pitchAuthority


        --------------------------------------------------
        -- START RAMP
        --------------------------------------------------

        yawCommand =
            yawCommand *
            controlScale


        pitchCommand =
            pitchCommand *
            controlScale


        --------------------------------------------------
        -- FINAL LIMIT
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
        -- SLEW LIMIT
        --------------------------------------------------

        currentCommandX =
            approach(
                currentCommandX,
                yawCommand,
                MAX_COMMAND_STEP
            )


        currentCommandY =
            approach(
                currentCommandY,
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