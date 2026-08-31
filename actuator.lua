-- Missile Control System
-- Multi-engine vector actuator
--
-- ACTUATOR VERSION 2
--
-- Responsibilities:
--   * detect liquid/vector thrusters
--   * receive Guidance commandX / commandY
--   * apply phase safety limits
--   * send exactly the resulting X/Y vector
--   * report requested/applied/actual vector
--
-- Coordinate handling is NOT performed here.
--
-- Guidance:
--   commandX = yaw
--   commandY = pitch
--
-- Actuator:
--   sends X/Y unchanged.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL =
    0.05


local MAX_VECTOR =
    1.0


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
-- CHECK THRUSTER
--------------------------------------------------

local function isVectorThruster(
    name
)

    local methods =
        peripheral.getMethods(
            name
        )


    if type(methods) ~=
        "table" then

        return false

    end


    local hasSetVector =
        false


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


    return
        hasSetVector
        or
        (
            hasX
            and
            hasY
        )

end


--------------------------------------------------
-- FIND THRUSTERS
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
                        name =
                            name,

                        device =
                            device,

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
            "INVALID DEVICE"

    end


    local methods =
        peripheral.getMethods(
            entry.name
        )


    local hasSetVector =
        false


    local hasX =
        false


    local hasY =
        false


    if type(methods) ==
        "table" then

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

    end


    --------------------------------------------------
    -- PREFERRED API
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
    -- FALLBACK API
    --------------------------------------------------

    if hasX
        and
        hasY then

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
-- SET NEUTRAL
--------------------------------------------------

local function setNeutral(
    state,
    thrusters
)

    for _, entry in ipairs(
        thrusters
    ) do

        callVector(
            entry,
            0,
            0
        )

    end


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

end


--------------------------------------------------
-- PHASE
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
    -- NO THRUSTERS
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


        state.thruster.commandedEngines =
            0


        return

    end


    --------------------------------------------------
    -- GUIDANCE
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
    -- REQUESTED VECTOR
    --------------------------------------------------

    local requestedX =
        clamp(
            state.guidance.commandX,
            -MAX_VECTOR,
            MAX_VECTOR
        )


    local requestedY =
        clamp(
            state.guidance.commandY,
            -MAX_VECTOR,
            MAX_VECTOR
        )


    state.thruster.requestedVectorX =
        requestedX


    state.thruster.requestedVectorY =
        requestedY


    --------------------------------------------------
    -- PHASE
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
    --------------------------------------------------

    if phase ==
        "BOOST" then

        appliedX =
            0

        appliedY =
            0

    else

        --------------------------------------------------
        -- GUIDANCE LIMIT
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


            appliedX =
                clamp(
                    appliedX,
                    -limit,
                    limit
                )


            appliedY =
                clamp(
                    appliedY,
                    -limit,
                    limit
                )

        end

    end


    --------------------------------------------------
    -- SAVE APPLIED
    --------------------------------------------------

    state.thruster.appliedVectorX =
        appliedX


    state.thruster.appliedVectorY =
        appliedY


    --------------------------------------------------
    -- TARGET VECTOR
    --
    -- This is the vector we actually ask the engines
    -- to reach.
    --------------------------------------------------

    state.thruster.targetVectorX =
        appliedX


    state.thruster.targetVectorY =
        appliedY


    --------------------------------------------------
    -- SEND
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
    -- SAVE
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


    --------------------------------------------------
    -- USE FIRST THRUSTER
    --
    -- All engines receive the same requested vector.
    --------------------------------------------------

    local entry =
        thrusters[1]


    local device =
        entry.device


    --------------------------------------------------
    -- CURRENT X
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

    else

        state.thruster.vectorX =
            0

    end


    --------------------------------------------------
    -- CURRENT Y
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

    else

        state.thruster.vectorY =
            0

    end


    --------------------------------------------------
    -- TARGET X
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
    -- TARGET Y
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
    -- LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do

        local thrusters =
            findThrusters()


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


        if #thrusters > 0 then

            state.thruster.online =
                true

        else

            state.thruster.online =
                false

        end


        --------------------------------------------------
        -- APPLY COMMAND
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
    -- SHUTDOWN
    --------------------------------------------------

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