-- Missile Control System
-- Multi-engine actuator controller
--
-- Detects vector thrusters by their API.
--
-- IMPORTANT:
-- Guidance produces a REQUESTED vector.
-- Actuator applies a phase-dependent SAFE vector.
--
-- BOOST:
--   requested vector may be non-zero
--   applied vector is forced to ZERO
--
-- PITCH OVER / CRUISE / TERMINAL:
--   requested vector is limited by flightMaxVector
--
-- All detected vector thrusters receive the same
-- final applied vector.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

local MAX_VECTOR = 1.0


--------------------------------------------------
-- CLAMP
--------------------------------------------------

local function clamp(
    value
)

    value =
        tonumber(value) or 0


    if value > MAX_VECTOR then

        return MAX_VECTOR

    end


    if value < -MAX_VECTOR then

        return -MAX_VECTOR

    end


    return value

end


--------------------------------------------------
-- CHECK VECTOR THRUSTER
--------------------------------------------------

local function isVectorThruster(
    name
)

    local methods =
        peripheral.getMethods(
            name
        )


    if type(methods) ~= "table" then

        return false

    end


    local hasSetVector =
        false


    local hasVectorX =
        false


    local hasVectorY =
        false


    for _, method in ipairs(
        methods
    ) do

        if method ==
            "setVector" then

            hasSetVector =
                true


        elseif method ==
            "setVectorX" then

            hasVectorX =
                true


        elseif method ==
            "setVectorY" then

            hasVectorY =
                true

        end

    end


    return
        hasSetVector
        or
        (
            hasVectorX
            and
            hasVectorY
        )

end


--------------------------------------------------
-- FIND ALL VECTOR THRUSTERS
--------------------------------------------------

local function findThrusters()

    local result =
        {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if isVectorThruster(
            name
        ) then

            local device =
                peripheral.wrap(
                    name
                )


            if device then

                table.insert(
                    result,
                    {
                        name = name,
                        device = device,
                        type =
                            peripheral.getType(
                                name
                            )
                    }
                )

            end

        end

    end


    return result

end


--------------------------------------------------
-- UPDATE ENGINE LIST
--------------------------------------------------

local function updateEngineList(
    state,
    thrusters
)

    state.thruster.engineCount =
        #thrusters


    state.thruster.engines =
        {}


    for index, entry in ipairs(
        thrusters
    ) do

        state.thruster.engines[index] =
            {
                name =
                    entry.name,

                type =
                    entry.type
            }

    end

end


--------------------------------------------------
-- CALL VECTOR
--------------------------------------------------

local function callVector(
    entry,
    x,
    y
)

    if not entry
        or
        not entry.device then

        return false,
            "DEVICE INVALID"

    end


    local methods =
        peripheral.getMethods(
            entry.name
        )


    local hasSetVector =
        false


    local hasAxisMethods =
        false


    if type(methods) ==
        "table" then

        local hasX =
            false


        local hasY =
            false


        for _, method in ipairs(
            methods
        ) do

            if method ==
                "setVector" then

                hasSetVector =
                    true


            elseif method ==
                "setVectorX" then

                hasX =
                    true


            elseif method ==
                "setVectorY" then

                hasY =
                    true

            end

        end


        hasAxisMethods =
            hasX and hasY

    end


    --------------------------------------------------
    -- setVector(x, y)
    --------------------------------------------------

    if hasSetVector then

        local ok,
            err =
            pcall(
                function()

                    entry.device.setVector(
                        x,
                        y
                    )

                end
            )


        if ok then

            return true,
                nil

        end


        return false,
            tostring(
                err
            )

    end


    --------------------------------------------------
    -- setVectorX / setVectorY
    --------------------------------------------------

    if hasAxisMethods then

        local ok,
            err =
            pcall(
                function()

                    entry.device.setVectorX(
                        x
                    )


                    entry.device.setVectorY(
                        y
                    )

                end
            )


        if ok then

            return true,
                nil

        end


        return false,
            tostring(
                err
            )

    end


    return false,
        "NO VECTOR API"

end


--------------------------------------------------
-- NEUTRALIZE ALL
--------------------------------------------------

local function setNeutral(
    state,
    thrusters
)

    local successful =
        0


    local errors =
        {}


    for _, entry in ipairs(
        thrusters
    ) do

        local ok,
            err =
            callVector(
                entry,
                0,
                0
            )


        if ok then

            successful =
                successful + 1

        else

            errors[
                entry.name
            ] =
                err
                or
                "UNKNOWN ERROR"

        end

    end


    state.thruster.commandedEngines =
        successful


    state.thruster.commandErrors =
        errors


    --------------------------------------------------
    -- Applied vector
    --------------------------------------------------

    state.thruster.appliedVectorX =
        0


    state.thruster.appliedVectorY =
        0


    state.thruster.targetVectorX =
        0


    state.thruster.targetVectorY =
        0

end


--------------------------------------------------
-- GET PHASE
--------------------------------------------------

local function getPhase(
    state
)

    if type(
        state.flight
    ) ~= "table" then

        return "READY"

    end


    return
        state.flight.phase
        or
        "READY"

end


--------------------------------------------------
-- APPLY COMMAND
--------------------------------------------------

local function applyCommand(
    state,
    thrusters
)

    --------------------------------------------------
    -- NO ENGINES
    --------------------------------------------------

    if #thrusters == 0 then

        state.thruster.commandedEngines =
            0


        state.thruster.status =
            "NO ENGINES"


        state.thruster.appliedVectorX =
            0


        state.thruster.appliedVectorY =
            0


        return

    end


    --------------------------------------------------
    -- CONTROL OFF
    --------------------------------------------------

    if not state.system.controlEnabled then

        setNeutral(
            state,
            thrusters
        )


        state.thruster.status =
            "CONTROL OFF"


        return

    end


    --------------------------------------------------
    -- GUIDANCE CHECK
    --------------------------------------------------

    if type(
        state.guidance
    ) ~= "table" then

        setNeutral(
            state,
            thrusters
        )


        state.thruster.status =
            "NO GUIDANCE"


        return

    end


    --------------------------------------------------
    -- REQUESTED COMMAND
    --------------------------------------------------

    local requestedX =
        clamp(
            state.guidance.commandX
        )


    local requestedY =
        clamp(
            state.guidance.commandY
        )


    --------------------------------------------------
    -- SAVE REQUESTED COMMAND
    --------------------------------------------------

    state.thruster.requestedVectorX =
        requestedX


    state.thruster.requestedVectorY =
        requestedY


    --------------------------------------------------
    -- PHASE SAFETY
    --------------------------------------------------

    local phase =
        getPhase(
            state
        )


    local appliedX =
        requestedX


    local appliedY =
        requestedY


    --------------------------------------------------
    -- BOOST
    --
    -- No vector steering during initial boost.
    --------------------------------------------------

    if phase ==
        "BOOST" then

        appliedX =
            0


        appliedY =
            0

    else

        --------------------------------------------------
        -- FLIGHT LIMIT
        --------------------------------------------------

        local limit =
            tonumber(
                state.guidance.flightMaxVector
            )


        if limit then

            limit =
                math.abs(
                    limit
                )


            if limit <
                MAX_VECTOR then

                appliedX =
                    math.max(
                        -limit,
                        math.min(
                            appliedX,
                            limit
                        )
                    )


                appliedY =
                    math.max(
                        -limit,
                        math.min(
                            appliedY,
                            limit
                        )
                    )

            end

        end

    end


    --------------------------------------------------
    -- SAVE APPLIED VECTOR
    --------------------------------------------------

    state.thruster.appliedVectorX =
        appliedX


    state.thruster.appliedVectorY =
        appliedY


    --------------------------------------------------
    -- COMPATIBILITY:
    -- targetVector = ACTUAL vector sent
    --------------------------------------------------

    state.thruster.targetVectorX =
        appliedX


    state.thruster.targetVectorY =
        appliedY


    --------------------------------------------------
    -- SEND TO ALL ENGINES
    --------------------------------------------------

    local successful =
        0


    local errors =
        {}


    for _, entry in ipairs(
        thrusters
    ) do

        local ok,
            err =
            callVector(
                entry,
                appliedX,
                appliedY
            )


        if ok then

            successful =
                successful + 1

        else

            errors[
                entry.name
            ] =
                err
                or
                "UNKNOWN ERROR"

        end

    end


    --------------------------------------------------
    -- SAVE RESULT
    --------------------------------------------------

    state.thruster.commandedEngines =
        successful


    state.thruster.commandErrors =
        errors


    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    if successful ==
        #thrusters then

        if phase ==
            "BOOST" then

            state.thruster.status =
                "BOOST NEUTRAL"

        else

            state.thruster.status =
                "ALL ENGINES OK"

        end


    elseif successful > 0 then

        state.thruster.status =
            "PARTIAL"


    else

        state.thruster.status =
            "COMMAND FAILED"

    end

end


--------------------------------------------------
-- TELEMETRY
--------------------------------------------------

local function updateTelemetry(
    state,
    thrusters
)

    if #thrusters == 0 then

        return

    end


    local entry =
        thrusters[1]


    local device =
        entry.device


    --------------------------------------------------
    -- CURRENT VECTOR X
    --------------------------------------------------

    local ok,
        value =
        pcall(
            function()

                return
                    device.getVectorX()

            end
        )


    if ok then

        state.thruster.vectorX =
            tonumber(value)
            or
            0

    end


    --------------------------------------------------
    -- CURRENT VECTOR Y
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return
                    device.getVectorY()

            end
        )


    if ok then

        state.thruster.vectorY =
            tonumber(value)
            or
            0

    end


    --------------------------------------------------
    -- TARGET VECTOR X
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return
                    device.getTargetVectorX()

            end
        )


    if ok then

        state.thruster.targetVectorX =
            tonumber(value)
            or
            state.thruster.targetVectorX

    end


    --------------------------------------------------
    -- TARGET VECTOR Y
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return
                    device.getTargetVectorY()

            end
        )


    if ok then

        state.thruster.targetVectorY =
            tonumber(value)
            or
            state.thruster.targetVectorY

    end


    --------------------------------------------------
    -- POWER
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return
                    device.getPower()

            end
        )


    if ok then

        state.thruster.power =
            tonumber(value)
            or
            0

    end


    --------------------------------------------------
    -- THRUST
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return
                    device.getThrust()

            end
        )


    if ok then

        state.thruster.thrust =
            tonumber(value)
            or
            0

    end

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(
    state
)

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    state.thruster =
        state.thruster
        or
        {}


    state.thruster.online =
        false


    state.thruster.status =
        "SCANNING"


    state.thruster.engineCount =
        0


    state.thruster.commandedEngines =
        0


    state.thruster.engines =
        {}


    state.thruster.commandErrors =
        {}


    state.thruster.vectorX =
        0


    state.thruster.vectorY =
        0


    state.thruster.requestedVectorX =
        0


    state.thruster.requestedVectorY =
        0


    state.thruster.appliedVectorX =
        0


    state.thruster.appliedVectorY =
        0


    state.thruster.targetVectorX =
        0


    state.thruster.targetVectorY =
        0


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do

        --------------------------------------------------
        -- SCAN
        --------------------------------------------------

        local thrusters =
            findThrusters()


        updateEngineList(
            state,
            thrusters
        )


        --------------------------------------------------
        -- ONLINE
        --------------------------------------------------

        if #thrusters > 0 then

            state.thruster.online =
                true

        else

            state.thruster.online =
                false

        end


        --------------------------------------------------
        -- COMMAND
        --------------------------------------------------

        applyCommand(
            state,
            thrusters
        )


        --------------------------------------------------
        -- TELEMETRY
        --------------------------------------------------

        updateTelemetry(
            state,
            thrusters
        )


        sleep(
            UPDATE_INTERVAL
        )

    end


    --------------------------------------------------
    -- SAFETY SHUTDOWN
    --------------------------------------------------

    state.system.controlEnabled =
        false


    local thrusters =
        findThrusters()


    setNeutral(
        state,
        thrusters
    )


    state.thruster.online =
        false


    state.thruster.status =
        "OFFLINE"

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}