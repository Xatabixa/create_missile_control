-- Flight Scenario Manager
-- Safe flight phase controller
-- No require()

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local BOOST_TIME = 4.0

local PITCH_OVER_TIME = 6.0

local TERMINAL_DISTANCE = 500.0

local IMPACT_DISTANCE = 5.0

local MIN_BOOST_ALTITUDE = 30.0

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

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


    local previousControl =
        false


    local previousPhase =
        "READY"


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
    -- START
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
    -- DISTANCE
    --------------------------------------------------

    local function getDistance()

        if type(
            state.navigation
        ) ~= "table" then

            return nil
        end


        if type(
            state.target
        ) ~= "table"
        or
        state.target.set ~= true then

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
    -- ALTITUDE
    --------------------------------------------------

    local function getAltitude()

        if type(
            state.navigation
        ) ~= "table" then

            return nil
        end


        return tonumber(
            state.navigation.altitude
        )

    end


    --------------------------------------------------
    -- TIMERS
    --------------------------------------------------

    local function updateTimers()

        local now =
            os.clock()


        if state.flight.launchTime then

            state.flight.elapsed =
                now -
                state.flight.launchTime

        end


        state.flight.phaseElapsed =
            now -
            state.flight.phaseStartTime

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

            state.flight.active =
                false

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
        --
        -- IMPORTANT:
        -- Only check impact when a real target
        -- has been explicitly set.
        --------------------------------------------------

        if distance
            and distance > 0
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
                and distance >
                    IMPACT_DISTANCE
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

            return

        end

    end


    --------------------------------------------------
    -- PUBLISH
    --------------------------------------------------

    local function publish()

        state.flight.boost =
            state.flight.phase ==
            "BOOST"


        state.flight.pitchOver =
            state.flight.phase ==
            "PITCH OVER"


        state.flight.cruise =
            state.flight.phase ==
            "CRUISE"


        state.flight.terminal =
            state.flight.phase ==
            "TERMINAL"


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
        -- MAX VECTOR
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
        -- PHASE CHANGE
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
        -- STATUS
        --------------------------------------------------

        if state.flight.phase ==
            "READY" then

            state.flight.status =
                "READY"

        elseif state.flight.phase ==
            "BOOST" then

            state.flight.status =
                "BOOST"

        elseif state.flight.phase ==
            "PITCH OVER" then

            state.flight.status =
                "PITCH OVER"

        elseif state.flight.phase ==
            "CRUISE" then

            state.flight.status =
                "CRUISE"

        elseif state.flight.phase ==
            "TERMINAL" then

            state.flight.status =
                "TERMINAL"

        elseif state.flight.phase ==
            "IMPACT" then

            state.flight.status =
                "IMPACT"

        elseif state.flight.phase ==
            "ABORT" then

            state.flight.status =
                "ABORT"

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
-- EXPORT
--------------------------------------------------

return {
    run = run
}