-- Actuator System
-- Multi-engine vector-thrust control
-- CC:Tweaked
--
-- Controls ALL connected Liquid Vector Thrusters.
--
-- No require() is used.
-- launcher.lua passes shared state to run(state).

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

    local result = {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        local ptype =
            peripheral.getType(name)


        if ptype ==
            "vector_thruster"
            or
            ptype ==
            "liquid_vector_thruster" then

            local device =
                peripheral.wrap(name)


            if device then

                table.insert(
                    result,
                    {
                        name = name,
                        device = device
                    }
                )

            end

        end

    end


    return result
end


--------------------------------------------------
-- NEUTRAL
--------------------------------------------------

local function setNeutral(
    state,
    thrusters
)

    for _, entry in ipairs(
        thrusters
    ) do

        pcall(
            function()

                entry.device.setVector(
                    0,
                    0
                )

            end
        )

    end


    state.thruster.targetVectorX =
        0


    state.thruster.targetVectorY =
        0


    state.thruster.vectorX =
        0


    state.thruster.vectorY =
        0

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
    -- Use first engine as telemetry source.
    --------------------------------------------------

    local thruster =
        thrusters[1].device


    --------------------------------------------------
    -- Current X
    --------------------------------------------------

    local ok,
    value =
        pcall(
            function()
                return thruster.getVectorX()
            end
        )


    if ok and value ~= nil then

        state.thruster.vectorX =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- Current Y
    --------------------------------------------------

    ok, value =
        pcall(
            function()
                return thruster.getVectorY()
            end
        )


    if ok and value ~= nil then

        state.thruster.vectorY =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- Target X
    --------------------------------------------------

    ok, value =
        pcall(
            function()
                return thruster.getTargetVectorX()
            end
        )


    if ok and value ~= nil then

        state.thruster.targetVectorX =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- Target Y
    --------------------------------------------------

    ok, value =
        pcall(
            function()
                return thruster.getTargetVectorY()
            end
        )


    if ok and value ~= nil then

        state.thruster.targetVectorY =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- Power
    --------------------------------------------------

    ok, value =
        pcall(
            function()
                return thruster.getPower()
            end
        )


    if ok and value ~= nil then

        state.thruster.power =
            tonumber(value) or 0

    end


    --------------------------------------------------
    -- Thrust
    --------------------------------------------------

    ok, value =
        pcall(
            function()
                return thruster.getThrust()
            end
        )


    if ok and value ~= nil then

        state.thruster.thrust =
            tonumber(value) or 0

    end

end


--------------------------------------------------
-- APPLY GUIDANCE
--------------------------------------------------

local function applyGuidance(
    state,
    thrusters
)

    --------------------------------------------------
    -- No engines
    --------------------------------------------------

    if #thrusters == 0 then

        return

    end


    --------------------------------------------------
    -- CONTROL DISABLED
    --------------------------------------------------

    if not state.system.controlEnabled then

        setNeutral(
            state,
            thrusters
        )

        return

    end


    --------------------------------------------------
    -- GUIDANCE UNAVAILABLE
    --------------------------------------------------

    if type(state.guidance) ~= "table"
        or
        not state.guidance.online then

        setNeutral(
            state,
            thrusters
        )

        return

    end


    --------------------------------------------------
    -- GUIDANCE NOT ACTIVE
    --------------------------------------------------

    if not state.guidance.active then

        setNeutral(
            state,
            thrusters
        )

        return

    end


    --------------------------------------------------
    -- COMMAND X
    --------------------------------------------------

    local commandX =
        clamp(
            state.guidance.commandX
        )


    --------------------------------------------------
    -- COMMAND Y
    --------------------------------------------------

    local commandY =
        clamp(
            state.guidance.commandY
        )


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

    for _, entry in ipairs(
        thrusters
    ) do

        pcall(
            function()

                entry.device.setVector(
                    commandX,
                    commandY
                )

            end
        )

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


    state.thruster.engines =
        {}


    --------------------------------------------------
    -- FIND ENGINES
    --------------------------------------------------

    local thrusters =
        findThrusters()


    --------------------------------------------------
    -- NO ENGINES
    --------------------------------------------------

    if #thrusters == 0 then

        state.thruster.online =
            false


        state.thruster.status =
            "OFFLINE"


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


    state.thruster.engineCount =
        #thrusters


    --------------------------------------------------
    -- SAVE ENGINE NAMES
    --------------------------------------------------

    state.thruster.engines =
        {}


    for _, entry in ipairs(
        thrusters
    ) do

        table.insert(
            state.thruster.engines,
            entry.name
        )

    end


    --------------------------------------------------
    -- START NEUTRAL
    --------------------------------------------------

    setNeutral(
        state,
        thrusters
    )


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do


        --------------------------------------------------
        -- APPLY COMMAND TO ALL
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


        --------------------------------------------------
        -- UPDATE ENGINE COUNT
        --------------------------------------------------

        state.thruster.engineCount =
            #thrusters


        sleep(
            UPDATE_INTERVAL
        )

    end


    --------------------------------------------------
    -- SAFETY SHUTDOWN
    --------------------------------------------------

    state.system.controlEnabled =
        false


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
-- MODULE EXPORT
--------------------------------------------------

return {
    run = run
}