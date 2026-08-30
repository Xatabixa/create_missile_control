-- Missile Flight Scenario Manager
-- Single-folder ComputerCraft compatible version
--
-- This module controls the logical flight phase.
--
-- Phases:
--   READY
--   BOOST
--   PITCH OVER
--   CRUISE
--   TERMINAL
--   IMPACT
--   ABORT
--
-- The module does NOT directly control the thruster.
-- It publishes flight information into state.flight
-- and state.guidance so other modules can use it.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

-- Time spent in BOOST after control is enabled.
local BOOST_TIME = 4.0

-- Time spent performing the initial pitch-over.
local PITCH_OVER_TIME = 6.0

-- Distance at which terminal guidance begins.
local TERMINAL_DISTANCE = 500.0

-- Distance considered an impact.
local IMPACT_DISTANCE = 5.0

-- Minimum altitude during which the missile remains
-- in the initial boost phase.
local MIN_BOOST_ALTITUDE = 30.0

-- Update interval.
local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- INITIALIZE
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- CREATE FLIGHT STATE
    --------------------------------------------------

    state.flight =
        state.flight or {}


    state.flight.online =
        true


    state.flight.active =
        false


    state.flight.phase =
        "READY"


    state.flight.status =
        "READY"


    state.flight.elapsed =
        0


    state.flight.phaseElapsed =
        0


    state.flight.launchTime =
        nil


    state.flight.phaseStartTime =
        os.clock()


    state.flight.terminal =
        false


    state.flight.impact =
        false


    state.flight.abort =
        false


    state.flight.targetReached =
        false


    --------------------------------------------------
    -- INTERNAL STATE
    --------------------------------------------------

    local previousControl =
        false


    local previousPhase =
        "READY"


    --------------------------------------------------
    -- TIME
    --------------------------------------------------

    local systemStart =
        os.clock()


    --------------------------------------------------
    -- SET PHASE
    --------------------------------------------------

    local function setPhase(
        phase
    )

        if state.flight.phase ==
            phase then

            return
        end


        state.flight.phase =
            phase


        state.flight.status =
            phase


        state.flight.phaseStartTime =
            os.clock()


        state.flight.phaseElapsed =
            0

    end


    --------------------------------------------------
    -- START FLIGHT
    --------------------------------------------------

    local function startFlight()

        state.flight.active =
            true


        state.flight.abort =
            false


        state.flight.impact =
            false


        state.flight.targetReached =
            false


        state.flight.launchTime =
            os.clock()


        state.flight.phaseStartTime =
            os.clock()


        state.flight.elapsed =
            0


        state.flight.phaseElapsed =
            0


        setPhase(
            "BOOST"
        )


        state.system.mode =
            "FLIGHT"


    end


    --------------------------------------------------
    -- ABORT
    --------------------------------------------------

    local function abortFlight()

        state.flight.abort =
            true


        state.flight.active =
            false


        state.flight.terminal =
            false


        setPhase(
            "ABORT"
        )


        state.system.mode =
            "ABORT"


    end


    --------------------------------------------------
    -- UPDATE TIMER
    --------------------------------------------------

    local function updateTimers()

        local now =
            os.clock()


        if state.flight.launchTime then

            state.flight.elapsed =
                now -
                state.flight.launchTime

        else

            state.flight.elapsed =
                now -
                systemStart

        end


        state.flight.phaseElapsed =
            now -
            state.flight.phaseStartTime

    end


    --------------------------------------------------
    -- CHECK TARGET
    --------------------------------------------------

    local function getDistance()

        if type(state.navigation)
            ~= "table" then

            return nil
        end


        local distance =
            tonumber(
                state.navigation.distance
            )


        if not distance then
            return nil
        end


        return distance

    end


    --------------------------------------------------
    -- CHECK ALTITUDE
    --------------------------------------------------

    local function getAltitude()

        if type(state.navigation)
            ~= "table" then

            return nil
        end


        local altitude =
            tonumber(
                state.navigation.altitude
            )


        return altitude

    end


    --------------------------------------------------
    -- PHASE LOGIC
    --------------------------------------------------

    local function updatePhase()

        --------------------------------------------------
        -- ABORT
        --------------------------------------------------

        if state.flight.abort then

            setPhase(
                "ABORT"
            )

            return

        end


        --------------------------------------------------
        -- NOT ACTIVE
        --------------------------------------------------

        if not state.flight.active then

            setPhase(
                "READY"
            )

            return

        end


        --------------------------------------------------
        -- DISTANCE
        --------------------------------------------------

        local distance =
            getDistance()


        --------------------------------------------------
        -- IMPACT
        --------------------------------------------------

        if distance
            and distance <=
            IMPACT_DISTANCE then

            state.flight.impact =
                true


            state.flight.targetReached =
                true


            state.flight.active =
                false


            setPhase(
                "IMPACT"
            )


            state.system.controlEnabled =
                false


            return

        end


        --------------------------------------------------
        -- BOOST
        --------------------------------------------------

        if state.flight.phase ==
            "BOOST" then

            local altitude =
                getAltitude()


            local timeFinished =
                state.flight.phaseElapsed
                >= BOOST_TIME


            local altitudeFinished =
                altitude ~= nil
                and altitude >=
                MIN_BOOST_ALTITUDE


            if timeFinished
                or altitudeFinished then

                setPhase(
                    "PITCH OVER"
                )

            end


            return

        end


        --------------------------------------------------
        -- PITCH OVER
        --------------------------------------------------

        if state.flight.phase ==
            "PITCH OVER" then

            if state.flight.phaseElapsed
                >= PITCH_OVER_TIME then

                setPhase(
                    "CRUISE"
                )

            end


            return

        end


        --------------------------------------------------
        -- CRUISE
        --------------------------------------------------

        if state.flight.phase ==
            "CRUISE" then

            if distance
                and distance <=
                TERMINAL_DISTANCE then

                state.flight.terminal =
                    true


                setPhase(
                    "TERMINAL"
                )

            end


            return

        end


        --------------------------------------------------
        -- TERMINAL
        --------------------------------------------------

        if state.flight.phase ==
            "TERMINAL" then

            state.flight.terminal =
                true


            if distance
                and distance <=
                IMPACT_DISTANCE then

                state.flight.impact =
                    true

                state.flight.targetReached =
                    true

                state.flight.active =
                    false

                setPhase(
                    "IMPACT"
                )

                state.system.controlEnabled =
                    false

            end


            return

        end

    end


    --------------------------------------------------
    -- PUBLISH FLIGHT PARAMETERS
    --------------------------------------------------

    local function publish()

        --------------------------------------------------
        -- DEFAULT VALUES
        --------------------------------------------------

        state.flight.boost =
            false

        state.flight.pitchOver =
            false

        state.flight.cruise =
            false

        state.flight.terminal =
            false


        --------------------------------------------------
        -- BOOST
        --------------------------------------------------

        if state.flight.phase ==
            "BOOST" then

            state.flight.boost =
                true

        end


        --------------------------------------------------
        -- PITCH OVER
        --------------------------------------------------

        if state.flight.phase ==
            "PITCH OVER" then

            state.flight.pitchOver =
                true

        end


        --------------------------------------------------
        -- CRUISE
        --------------------------------------------------

        if state.flight.phase ==
            "CRUISE" then

            state.flight.cruise =
                true

        end


        --------------------------------------------------
        -- TERMINAL
        --------------------------------------------------

        if state.flight.phase ==
            "TERMINAL" then

            state.flight.terminal =
                true

        end


        --------------------------------------------------
        -- GUIDANCE INFORMATION
        --------------------------------------------------
        --
        -- These values are intentionally published
        -- instead of directly modifying commandX/Y.
        --
        -- guidance.lua can use them later.
        --------------------------------------------------

        state.guidance =
            state.guidance or {}


        state.guidance.flightPhase =
            state.flight.phase


        state.guidance.flightTime =
            state.flight.elapsed


        state.guidance.phaseTime =
            state.flight.phaseElapsed


        state.guidance.boostMode =
            state.flight.boost


        state.guidance.pitchOverMode =
            state.flight.pitchOver


        state.guidance.cruiseMode =
            state.flight.cruise


        state.guidance.terminalMode =
            state.flight.terminal


        --------------------------------------------------
        -- PHASE LIMITS
        --------------------------------------------------
        --
        -- These values are ready for the next step,
        -- where guidance.lua will use them to limit
        -- how aggressively the missile turns.
        --------------------------------------------------

        if state.flight.phase ==
            "BOOST" then

            state.guidance.flightMaxVector =
                0.04


        elseif state.flight.phase ==
            "PITCH OVER" then

            state.guidance.flightMaxVector =
                0.08


        elseif state.flight.phase ==
            "CRUISE" then

            state.guidance.flightMaxVector =
                0.15


        elseif state.flight.phase ==
            "TERMINAL" then

            state.guidance.flightMaxVector =
                0.25


        else

            state.guidance.flightMaxVector =
                0

        end

    end


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do

        --------------------------------------------------
        -- CONTROL EDGE
        --------------------------------------------------

        local control =
            state.system.controlEnabled
            == true


        if control
            and not previousControl then

            if not state.flight.active
                and not state.flight.impact
                and not state.flight.abort then

                startFlight()

            end

        end


        --------------------------------------------------
        -- CONTROL DISABLED BEFORE FLIGHT
        --------------------------------------------------

        if not control
            and not state.flight.active
            and not state.flight.impact
            and not state.flight.abort then

            state.flight.phase =
                "READY"

        end


        previousControl =
            control


        --------------------------------------------------
        -- TIMERS
        --------------------------------------------------

        if state.flight.active then

            updateTimers()

        end


        --------------------------------------------------
        -- PHASE
        --------------------------------------------------

        updatePhase()


        --------------------------------------------------
        -- PUBLISH
        --------------------------------------------------

        publish()


        --------------------------------------------------
        -- PHASE CHANGE FLAG
        --------------------------------------------------

        if previousPhase ~=
            state.flight.phase then

            state.flight.phaseChanged =
                true

            previousPhase =
                state.flight.phase

        else

            state.flight.phaseChanged =
                false

        end


        --------------------------------------------------
        -- SYSTEM STATUS
        --------------------------------------------------

        if state.flight.phase ==
            "READY" then

            state.flight.status =
                "READY"


        elseif state.flight.phase ==
            "ABORT" then

            state.flight.status =
                "ABORT"


        elseif state.flight.phase ==
            "IMPACT" then

            state.flight.status =
                "IMPACT"


        else

            state.flight.status =
                "FLIGHT " ..
                state.flight.phase

        end


        sleep(
            UPDATE_INTERVAL
        )

    end


    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

    state.flight.active =
        false


    state.flight.online =
        false


    state.flight.status =
        "OFFLINE"


    state.guidance =
        state.guidance or {}


    state.guidance.flightMaxVector =
        0

end


--------------------------------------------------
-- MODULE EXPORT
--------------------------------------------------

return {
    run = run
}