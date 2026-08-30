-- Actuator System
-- Automatic vector-thrust control
-- Safe dry-test mode
--
-- IMPORTANT:
-- This module does NOT use require().
-- launcher.lua passes the shared state to run(state).

local MAX_VECTOR = 0.25
local UPDATE_INTERVAL = 0.05

--------------------------------------------------
-- Clamp actuator command
--------------------------------------------------

local function clamp(value)

    value = tonumber(value) or 0

    if value > MAX_VECTOR then
        return MAX_VECTOR
    end

    if value < -MAX_VECTOR then
        return -MAX_VECTOR
    end

    return value
end

--------------------------------------------------
-- Set neutral position
--------------------------------------------------

local function setNeutral(state, thruster)

    if thruster then
        pcall(
            thruster.setVector,
            0,
            0
        )
    end

    state.thruster.targetVectorX = 0
    state.thruster.targetVectorY = 0

    state.thruster.vectorX = 0
    state.thruster.vectorY = 0
end

--------------------------------------------------
-- Read telemetry
--------------------------------------------------

local function updateTelemetry(
    state,
    thruster
)

    if not thruster then
        return
    end

    local ok
    local value

    --------------------------------------------------
    -- Current X
    --------------------------------------------------

    ok, value =
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
-- Apply guidance command
--------------------------------------------------

local function applyGuidance(
    state,
    thruster
)

    if not thruster then
        return
    end

    --------------------------------------------------
    -- CONTROL DISABLED
    --
    -- Always return the nozzle to neutral.
    --------------------------------------------------

    if not state.system.controlEnabled then

        setNeutral(
            state,
            thruster
        )

        return
    end

    --------------------------------------------------
    -- GUIDANCE UNAVAILABLE
    --------------------------------------------------

    if type(state.guidance) ~= "table"
        or not state.guidance.online then

        setNeutral(
            state,
            thruster
        )

        return
    end

    --------------------------------------------------
    -- GUIDANCE NOT ACTIVE
    --------------------------------------------------

    if not state.guidance.active then

        setNeutral(
            state,
            thruster
        )

        return
    end

    --------------------------------------------------
    -- Read guidance commands
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
    -- Publish requested vector
    --------------------------------------------------

    state.thruster.targetVectorX =
        commandX

    state.thruster.targetVectorY =
        commandY

    --------------------------------------------------
    -- Send vector to thruster
    --------------------------------------------------

    pcall(
        function()
            thruster.setVector(
                commandX,
                commandY
            )
        end
    )
end

--------------------------------------------------
-- MAIN MODULE
--------------------------------------------------

local function run(state)

    --------------------------------------------------
    -- Ensure state tables exist
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

    --------------------------------------------------
    -- Find vector thruster
    --------------------------------------------------

    local thruster =
        peripheral.find(
            "vector_thruster"
        )

    if not thruster then

        thruster =
            peripheral.find(
                "liquid_vector_thruster"
            )
    end

    --------------------------------------------------
    -- Peripheral missing
    --------------------------------------------------

    if not thruster then

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
    -- Thruster online
    --------------------------------------------------

    state.thruster.online =
        true

    state.thruster.status =
        "ONLINE"

    --------------------------------------------------
    -- SAFETY:
    -- Start with neutral nozzle.
    --------------------------------------------------

    setNeutral(
        state,
        thruster
    )

    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and state.system.running do

        --------------------------------------------------
        -- Apply automatic guidance command
        --------------------------------------------------

        applyGuidance(
            state,
            thruster
        )

        --------------------------------------------------
        -- Update telemetry
        --------------------------------------------------

        updateTelemetry(
            state,
            thruster
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

    setNeutral(
        state,
        thruster
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