-- Missile Flight Scenario Manager
-- Height-based flight profile
-- No require()

--------------------------------------------------
-- FLIGHT PROFILE
--------------------------------------------------

-- Vertical boost ends at this altitude.
local BOOST_ALTITUDE = 100.0

-- Pitch-over phase ends at this altitude.
local CRUISE_ALTITUDE = 300.0

-- Terminal guidance starts at this distance.
local TERMINAL_DISTANCE = 500.0

-- Target is considered reached at this distance.
local IMPACT_DISTANCE = 5.0


--------------------------------------------------
-- PITCH OVER
--------------------------------------------------

-- Minimum amount of time spent in pitch-over.
--
-- This prevents switching immediately from BOOST
-- to CRUISE due to a noisy altitude measurement.

local MIN_PITCH_OVER_TIME = 3.0


--------------------------------------------------
-- UPDATE
--------------------------------------------------

local UPDATE_INTERVAL = 0.05


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- CREATE STATE
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


    state.flight.phaseChanged =
        false


    --------------------------------------------------
    -- PREVIOUS CONTROL
    --------------------------------------------------

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


        state.flight.phaseChanged =
            true

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


        state.flight.terminal =
            false


        state.flight.launchTime =
            os.clock()


        state.flight.phaseStartTime =
            os.clock()


        state.flight.elapsed =
            0


        state.flight.phaseElapsed =
            0


        state.flight.phaseChanged =
            true


        setPhase(
            "BOOST"
        )


        state.system.mode =
            "FLIGHT"


        state.system.status =
            "FLIGHT BOOST"

    end


    --------------------------------------------------
    -- DISTANCE
    --------------------------------------------------

    local function getDistance()

        if type(state.target) ~=
            "table" then

            return nil

        end


        if state.target.set ~=
            true then

            return nil

        end


        if type(state.navigation) ~=
            "table" then

            return nil

        end


        local distance =
            tonumber(
                state.navigation.distance
            )


        if not distance then

            return nil

        end


        if distance < 0 then

            return nil

        end


        return distance

    end


    --------------------------------------------------
    -- ALTITUDE
    --------------------------------------------------

    local function getAltitude()

        if type(state.navigation) ~=
            "table" then

            return nil

        end


        local altitude =
            tonumber(
                state.navigation.altitude
            )


        if not altitude then

            return nil

        end


        return altitude

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

        else

            state.flight.elapsed =
                0

        end


        state.flight.phaseElapsed =
            now -
            state.flight.phaseStartTime

    end


    --------------------------------------------------
    -- TARGET VALIDATION
    --------------------------------------------------

    local function targetAvailable()

        return
            type(state.target) ==
                "table"
            and
            state.target.set == true

    end


    --------------------------------------------------
    -- PHASE LOGIC
    --------------------------------------------------

    local function updatePhase()

        --------------------------------------------------
        -- ABORT
        --------------------------------------------------

        if state.flight.abort then

            state.flight.active =
                false

            setPhase(
                "ABORT"
            )

            return

        end


        --------------------------------------------------
        -- NOT ACTIVE
        --------------------------------------------------

        if not state.flight.active then

            return

        end


        --------------------------------------------------
        -- TARGET DISTANCE
        --------------------------------------------------

        local distance =
            getDistance()


        --------------------------------------------------
        -- IMPACT
        --------------------------------------------------

        if targetAvailable()
            and
            distance
            and
            distance > 0
            and
            distance <=
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


            --------------------------------------------------
            -- Disable control after target is reached.
            --------------------------------------------------

            state.system.controlEnabled =
                false


            return

        end


        --------------------------------------------------
        -- ALTITUDE
        --------------------------------------------------

        local altitude =
            getAltitude()


        --------------------------------------------------
        -- BOOST
        --------------------------------------------------

        if state.flight.phase ==
            "BOOST" then

            --------------------------------------------------
            -- Stay in BOOST until the desired altitude
            -- is actually reached.
            --------------------------------------------------

            if altitude
                and
                altitude >=
                BOOST_ALTITUDE then

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

            --------------------------------------------------
            -- Wait for minimum pitch-over time.
            --------------------------------------------------

            if state.flight.phaseElapsed <
                MIN_PITCH_OVER_TIME then

                return

            end


            --------------------------------------------------
            -- Continue pitch-over until cruise altitude.
            --------------------------------------------------

            if altitude
                and
                altitude >=
                CRUISE_ALTITUDE then

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

            --------------------------------------------------
            -- Start terminal phase when approaching target.
            --------------------------------------------------

            if distance
                and
                distance >
                IMPACT_DISTANCE
                and
                distance <=
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

        --------------------------------------------------
        -- PHASE FLAGS
        --------------------------------------------------

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


        --------------------------------------------------
        -- GUIDANCE DATA
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
        -- ALTITUDE DATA
        --------------------------------------------------

        state.flight.altitude =
            getAltitude()


        state.flight.targetDistance =
            getDistance()


        --------------------------------------------------
        -- VECTOR LIMIT
        --------------------------------------------------

        if state.flight.phase ==
            "BOOST" then

            --------------------------------------------------
            -- Almost straight during vertical boost.
            --------------------------------------------------

            state.guidance.flightMaxVector =
                0.035


        elseif state.flight.phase ==
            "PITCH OVER" then

            --------------------------------------------------
            -- Gentle turning during pitch-over.
            --------------------------------------------------

            state.guidance.flightMaxVector =
                0.070


        elseif state.flight.phase ==
            "CRUISE" then

            --------------------------------------------------
            -- Normal cruise corrections.
            --------------------------------------------------

            state.guidance.flightMaxVector =
                0.150


        elseif state.flight.phase ==
            "TERMINAL" then

            --------------------------------------------------
            -- Full available correction.
            --------------------------------------------------

            state.guidance.flightMaxVector =
                0.250


        else

            state.guidance.flightMaxVector =
                0

        end


        --------------------------------------------------
        -- PROFILE LIMITS
        --------------------------------------------------

        state.guidance.boostAltitude =
            BOOST_ALTITUDE


        state.guidance.cruiseAltitude =
            CRUISE_ALTITUDE


        state.guidance.terminalDistance =
            TERMINAL_DISTANCE

    end


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do


        --------------------------------------------------
        -- CONTROL
        --------------------------------------------------

        local control =
            state.system.controlEnabled
            == true


        --------------------------------------------------
        -- CONTROL JUST ENABLED
        --------------------------------------------------

        if control
            and
            not previousControl then

            if not state.flight.active
                and
                not state.flight.impact
                and
                not state.flight.abort then

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
        -- CLEAR PHASE FLAG
        --------------------------------------------------

        state.flight.phaseChanged =
            false


        --------------------------------------------------
        -- UPDATE PHASE
        --------------------------------------------------

        updatePhase()


        --------------------------------------------------
        -- PUBLISH
        --------------------------------------------------

        publish()


        --------------------------------------------------
        -- PHASE CHANGE DETECTION
        --------------------------------------------------

        if previousPhase ~=
            state.flight.phase then

            state.flight.phaseChanged =
                true

            previousPhase =
                state.flight.phase

        end


        --------------------------------------------------
        -- SYSTEM STATUS
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


        --------------------------------------------------
        -- SYSTEM MODE
        --------------------------------------------------

        if state.flight.active then

            state.system.mode =
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
-- EXPORT
--------------------------------------------------

return {
    run = run
}