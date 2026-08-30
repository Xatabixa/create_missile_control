-- Missile Control System
-- Multi-engine actuator controller
--
-- Detects vector thrusters by their API instead
-- of relying only on peripheral type.
--
-- This is important because Create addons may
-- expose peripherals through different type names.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

local MAX_VECTOR = 1.0


--------------------------------------------------
-- CLAMP
--------------------------------------------------

local function clamp(value)

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

local function isVectorThruster(name)

    local methods =
        peripheral.getMethods(name)


    if type(methods) ~= "table" then
        return false
    end


    local hasSetVector =
        false

    local hasVectorX =
        false

    local hasVectorY =
        false


    for _, method in ipairs(methods) do

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
            and hasVectorY
        )

end


--------------------------------------------------
-- FIND ALL VECTOR THRUSTERS
--------------------------------------------------

local function findThrusters()

    local result = {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if isVectorThruster(name) then

            local device =
                peripheral.wrap(name)


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

        state.thruster.engines[index] = {

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
        or not entry.device then

        return false,
            "DEVICE INVALID"

    end


    --------------------------------------------------
    -- Preferred API
    --------------------------------------------------

    local methods =
        peripheral.getMethods(
            entry.name
        )


    local hasSetVector =
        false

    local hasAxisMethods =
        false


    if type(methods) == "table" then

        local hasX = false
        local hasY = false


        for _, method in ipairs(methods) do

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
            return true, nil
        end


        return false,
            tostring(err)

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
            return true, nil
        end


        return false,
            tostring(err)

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
                err or
                "UNKNOWN ERROR"

        end

    end


    state.thruster.commandedEngines =
        successful


    state.thruster.commandErrors =
        errors


    state.thruster.targetVectorX =
        0

    state.thruster.targetVectorY =
        0

end


--------------------------------------------------
-- APPLY COMMAND
--------------------------------------------------

local function applyCommand(
    state,
    thrusters
)

    if #thrusters == 0 then

        state.thruster.commandedEngines =
            0


        state.thruster.status =
            "NO ENGINES"


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

    if type(state.guidance)
        ~= "table" then

        setNeutral(
            state,
            thrusters
        )


        state.thruster.status =
            "NO GUIDANCE"


        return

    end


    --------------------------------------------------
    -- COMMAND
    --------------------------------------------------

    local x =
        clamp(
            state.guidance.commandX
        )


    local y =
        clamp(
            state.guidance.commandY
        )


    --------------------------------------------------
    -- FLIGHT LIMIT
    --------------------------------------------------

    local limit =
        tonumber(
            state.guidance.flightMaxVector
        )


    if limit then

        limit =
            math.abs(limit)


        if limit < MAX_VECTOR then

            x =
                math.max(
                    -limit,
                    math.min(
                        x,
                        limit
                    )
                )


            y =
                math.max(
                    -limit,
                    math.min(
                        y,
                        limit
                    )
                )

        end

    end


    --------------------------------------------------
    -- SAVE
    --------------------------------------------------

    state.thruster.targetVectorX =
        x

    state.thruster.targetVectorY =
        y


    --------------------------------------------------
    -- SEND TO ALL
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
                x,
                y
            )


        if ok then

            successful =
                successful + 1

        else

            errors[
                entry.name
            ] =
                err or
                "UNKNOWN ERROR"

        end

    end


    state.thruster.commandedEngines =
        successful


    state.thruster.commandErrors =
        errors


    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    if successful ==
        #thrusters then

        state.thruster.status =
            "ALL ENGINES OK"

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
    -- CURRENT VECTOR
    --------------------------------------------------

    local ok,
    value =
        pcall(
            function()

                return device.getVectorX()

            end
        )


    if ok then

        state.thruster.vectorX =
            tonumber(value) or 0

    end


    ok,
    value =
        pcall(
            function()

                return device.getVectorY()

            end
        )


    if ok then

        state.thruster.vectorY =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- TARGET VECTOR
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return device.getTargetVectorX()

            end
        )


    if ok then

        state.thruster.targetVectorX =
            tonumber(value) or
            state.thruster.targetVectorX

    end


    ok,
    value =
        pcall(
            function()

                return device.getTargetVectorY()

            end
        )


    if ok then

        state.thruster.targetVectorY =
            tonumber(value) or
            state.thruster.targetVectorY

    end


    --------------------------------------------------
    -- POWER
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return device.getPower()

            end
        )


    if ok then

        state.thruster.power =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- THRUST
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()

                return device.getThrust()

            end
        )


    if ok then

        state.thruster.thrust =
            tonumber(value) or 0

    end

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- STATE
    --------------------------------------------------

    state.thruster =
        state.thruster or {}


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


    state.thruster.targetVectorX =
        0

    state.thruster.targetVectorY =
        0


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do


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
        -- STATUS
        --------------------------------------------------

        if #thrusters > 0 then

            state.thruster.online =
                true

        else

            state.thruster.online =
                false

        end


        --------------------------------------------------
        -- CONTROL
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
    -- SAFETY
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