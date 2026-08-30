-- Actuator System
-- Multi-engine vector-thrust control
-- CC:Tweaked
--
-- Finds ALL connected vector thrusters.
--
-- Supported peripheral types:
--   vector_thruster
--   liquid_vector_thruster
--   creative_vector_thruster

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local MAX_VECTOR = 0.25

local UPDATE_INTERVAL = 0.05


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
-- FIND ALL THRUSTERS
--------------------------------------------------

local function findThrusters()

    local thrusters = {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        local pType =
            peripheral.getType(name)


        if pType ==
            "vector_thruster"
            or
            pType ==
            "liquid_vector_thruster"
            or
            pType ==
            "creative_vector_thruster" then


            local device =
                peripheral.wrap(name)


            if device then

                table.insert(
                    thrusters,
                    {
                        name = name,
                        type = pType,
                        device = device
                    }
                )

            end

        end

    end


    return thrusters
end


--------------------------------------------------
-- WRITE ENGINE INFO INTO STATE
--------------------------------------------------

local function updateEngineList(
    state,
    thrusters
)

    state.thruster.engineCount =
        #thrusters


    state.thruster.engines =
        {}


    for _, engine in ipairs(
        thrusters
    ) do

        table.insert(
            state.thruster.engines,
            {
                name = engine.name,
                type = engine.type
            }
        )

    end

end


--------------------------------------------------
-- SAFE VECTOR SET
--------------------------------------------------

local function setVector(
    engine,
    x,
    y
)

    if not engine then
        return false
    end


    local ok =
        pcall(
            function()

                engine.setVector(
                    x,
                    y
                )

            end
        )


    return ok
end


--------------------------------------------------
-- SET ALL NEUTRAL
--------------------------------------------------

local function setAllNeutral(
    thrusters
)

    for _, entry in ipairs(
        thrusters
    ) do

        setVector(
            entry.device,
            0,
            0
        )

    end

end


--------------------------------------------------
-- READ TELEMETRY
--------------------------------------------------

local function updateTelemetry(
    state,
    thrusters
)

    if #thrusters == 0 then
        return
    end


    --------------------------------------------------
    -- First engine is used as telemetry source.
    --
    -- The actual command is still sent to ALL engines.
    --------------------------------------------------

    local engine =
        thrusters[1].device


    --------------------------------------------------
    -- CURRENT X
    --------------------------------------------------

    local ok,
    value =
        pcall(
            function()
                return engine.getVectorX()
            end
        )


    if ok and value ~= nil then

        state.thruster.vectorX =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- CURRENT Y
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()
                return engine.getVectorY()
            end
        )


    if ok and value ~= nil then

        state.thruster.vectorY =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- TARGET X
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()
                return engine.getTargetVectorX()
            end
        )


    if ok and value ~= nil then

        state.thruster.targetVectorX =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- TARGET Y
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()
                return engine.getTargetVectorY()
            end
        )


    if ok and value ~= nil then

        state.thruster.targetVectorY =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- POWER
    --------------------------------------------------

    ok,
    value =
        pcall(
            function()
                return engine.getPower()
            end
        )


    if ok and value ~= nil then

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
                return engine.getThrust()
            end
        )


    if ok and value ~= nil then

        state.thruster.thrust =
            tonumber(value) or 0

    end

end


--------------------------------------------------
-- APPLY GUIDANCE TO ALL ENGINES
--------------------------------------------------

local function applyGuidance(
    state,
    thrusters
)

    --------------------------------------------------
    -- NO ENGINES
    --------------------------------------------------

    if #thrusters == 0 then

        return

    end


    --------------------------------------------------
    -- CONTROL OFF
    --------------------------------------------------

    if not state.system.controlEnabled then

        setAllNeutral(
            thrusters
        )

        return

    end


    --------------------------------------------------
    -- GUIDANCE OFFLINE
    --------------------------------------------------

    if type(state.guidance)
        ~= "table"
        or
        not state.guidance.online then

        setAllNeutral(
            thrusters
        )

        return

    end


    --------------------------------------------------
    -- GUIDANCE NOT ACTIVE
    --------------------------------------------------

    if not state.guidance.active then

        setAllNeutral(
            thrusters
        )

        return

    end


    --------------------------------------------------
    -- COMMAND
    --------------------------------------------------

    local commandX =
        clamp(
            state.guidance.commandX
        )


    local commandY =
        clamp(
            state.guidance.commandY
        )


    --------------------------------------------------
    -- FLIGHT LIMIT
    --------------------------------------------------

    local flightLimit =
        tonumber(
            state.guidance.flightMaxVector
        )


    if flightLimit then

        flightLimit =
            math.abs(
                flightLimit
            )


        if flightLimit < MAX_VECTOR then

            commandX =
                math.max(
                    -flightLimit,
                    math.min(
                        commandX,
                        flightLimit
                    )
                )


            commandY =
                math.max(
                    -flightLimit,
                    math.min(
                        commandY,
                        flightLimit
                    )
                )

        end

    end


    --------------------------------------------------
    -- PUBLISH
    --------------------------------------------------

    state.thruster.targetVectorX =
        commandX


    state.thruster.targetVectorY =
        commandY


    --------------------------------------------------
    -- SEND TO EVERY ENGINE
    --------------------------------------------------

    local successful =
        0


    for _, entry in ipairs(
        thrusters
    ) do

        if setVector(
            entry.device,
            commandX,
            commandY
        ) then

            successful =
                successful + 1

        end

    end


    state.thruster.commandedEngines =
        successful


    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    if successful ==
        #thrusters then

        state.thruster.status =
            "ONLINE"

    elseif successful > 0 then

        state.thruster.status =
            "PARTIAL"

    else

        state.thruster.status =
            "COMMAND ERROR"

    end

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- INITIAL STATE
    --------------------------------------------------

    state.thruster =
        state.thruster or {}


    state.thruster.online =
        false


    state.thruster.status =
        "STARTING"


    state.thruster.vectorX =
        0


    state.thruster.vectorY =
        0


    state.thruster.targetVectorX =
        0


    state.thruster.targetVectorY =
        0


    state.thruster.engineCount =
        0


    state.thruster.commandedEngines =
        0


    state.thruster.engines =
        {}


    --------------------------------------------------
    -- FIND ENGINES
    --------------------------------------------------

    local thrusters =
        findThrusters()


    --------------------------------------------------
    -- SAVE LIST
    --------------------------------------------------

    updateEngineList(
        state,
        thrusters
    )


    --------------------------------------------------
    -- NO ENGINES
    --------------------------------------------------

    if #thrusters == 0 then

        state.thruster.online =
            false


        state.thruster.status =
            "NO ENGINES"


        while state.system
            and state.system.running do

            sleep(1)

        end


        return
    end


    --------------------------------------------------
    -- ONLINE
    --------------------------------------------------

    state.thruster.online =
        true


    state.thruster.status =
        "ONLINE"


    --------------------------------------------------
    -- INITIAL NEUTRAL
    --------------------------------------------------

    setAllNeutral(
        thrusters
    )


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do


        --------------------------------------------------
        -- CHECK FOR NEW/DISCONNECTED ENGINES
        --------------------------------------------------

        local currentThrusters =
            findThrusters()


        if #currentThrusters ~=
            #thrusters then

            thrusters =
                currentThrusters


            updateEngineList(
                state,
                thrusters
            )

        end


        --------------------------------------------------
        -- APPLY COMMAND
        --------------------------------------------------

        applyGuidance(
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

    setAllNeutral(
        thrusters
    )


    state.system.controlEnabled =
        false


    state.thruster.online =
        false


    state.thruster.status =
        "OFFLINE"


    state.thruster.commandedEngines =
        0

end


--------------------------------------------------
-- MODULE EXPORT
--------------------------------------------------

return {
    run = run
}