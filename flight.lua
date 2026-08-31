-- Missile Flight Scenario Manager
-- CC:Tweaked
--
-- Flight phases:
--
--   READY
--      |
--      v
--   BOOST
--      |
--      | altitude >= 100
--      v
--   PITCH OVER
--      |
--      | altitude >= 300
--      v
--   CRUISE
--      |
--      | distance <= 500
--      v
--   TERMINAL
--      |
--      | distance <= 5
--      v
--   IMPACT
--
-- Conservative-but-useful steering limits:
--
--   BOOST       0.000
--   PITCH OVER  0.050
--   CRUISE      0.100
--   TERMINAL    0.250

--------------------------------------------------
-- PROFILE
--------------------------------------------------

local BOOST_ALTITUDE =
    100.0


local CRUISE_ALTITUDE =
    300.0


local TERMINAL_DISTANCE =
    500.0


local IMPACT_DISTANCE =
    5.0


--------------------------------------------------
-- PITCH OVER
--------------------------------------------------

local MIN_PITCH_OVER_TIME =
    3.0


--------------------------------------------------
-- VECTOR LIMITS
--------------------------------------------------

local BOOST_VECTOR_LIMIT =
    0.000


local PITCH_OVER_VECTOR_LIMIT =
    0.050


local CRUISE_VECTOR_LIMIT =
    0.100


local TERMINAL_VECTOR_LIMIT =
    0.250


--------------------------------------------------
-- UPDATE
--------------------------------------------------

local UPDATE_INTERVAL =
    0.05


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(
    state
)

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    state.flight =
        state.flight
        or
        {}


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

        if type(
            state.target
        ) ~= "table" then

            return nil

        end


        if state.target.set ~=
            true then

            return nil

        end


        if type(
            state.navigation
        ) ~= "table" then

            return nil

        end


        local distance =
            tonumber(
                state.navigation.distance
            )


        if not distance then

            distance =
                tonumber(
                    state.navigation.targetDistance
                )

        end


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

        if type(
            state.navigation
        ) ~= "table" then

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
    -- TARGET AVAILABLE
    --------------------------------------------------

    local function targetAvailable()

        return
            type(
                state.target
            ) == "table"
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
        -- DISTANCE
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
            distance <=
            IMPACT_DISTANCE then

            state.flight.impact =
                true


            state.flight.targetReached =
                true


            state.flight.active =
                false


            state.system.controlEnabled =
                false


            setPhase(
                "IMPACT"
            )


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

            if state.flight.phaseElapsed <
                MIN_PITCH_OVER_TIME then

                return

            end


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

            if distance
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

        state.guidance =
            state.guidance
            or
            {}


        state.guidance.flightPhase =
            state.flight.phase


        state.guidance.flightTime =
            state.flight.elapsed


        state.guidance.phaseTime =
            state.flight.phaseElapsed


        state.flight.altitude =
            getAltitude()


        state.flight.targetDistance =
            getDistance()


        --------------------------------------------------
        -- VECTOR LIMIT
        --------------------------------------------------

        if state.flight.phase ==
            "BOOST" then

            state.guidance.flightMaxVector =
                BOOST_VECTOR_LIMIT


        elseif state.flight.phase ==
            "PITCH OVER" then

            state.guidance.flightMaxVector =
                PITCH_OVER_VECTOR_LIMIT


        elseif state.flight.phase ==
            "CRUISE" then

            state.guidance.flightMaxVector =
                CRUISE_VECTOR_LIMIT


        elseif state.flight.phase ==
            "TERMINAL" then

            state.guidance.flightMaxVector =
                TERMINAL_VECTOR_LIMIT


        else

            state.guidance.flightMaxVector =
                0

        end


        --------------------------------------------------
        -- PROFILE INFO
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
        -- START ON CONTROL
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
        -- RESET PHASE CHANGE
        --------------------------------------------------

        state.flight.phaseChanged =
            false


        --------------------------------------------------
        -- PHASE
        --------------------------------------------------

        updatePhase()


        --------------------------------------------------
        -- PUBLISH
        --------------------------------------------------

        publish()


        --------------------------------------------------
        -- DETECT PHASE CHANGE
        --------------------------------------------------

        if previousPhase ~=
            state.flight.phase then

            state.flight.phaseChanged =
                true


            previousPhase =
                state.flight.phase

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
        state.guidance
        or
        {}


    state.guidance.flightMaxVector =
        0

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}