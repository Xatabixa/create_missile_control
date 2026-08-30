-- Vector thruster actuator
-- Dry automatic control test
-- CONTROL must be enabled before guidance commands reach the thruster.

local state = require("state")

local thruster =
    peripheral.find("vector_thruster")
    or peripheral.find("liquid_vector_thruster")

--------------------------------------------------
-- Limits
--------------------------------------------------

local MAX_VECTOR = 0.25

--------------------------------------------------
-- Clamp
--------------------------------------------------

local function clamp(value)

    value =
        tonumber(value) or 0

    if value < -MAX_VECTOR then
        return -MAX_VECTOR
    end

    if value > MAX_VECTOR then
        return MAX_VECTOR
    end

    return value
end

--------------------------------------------------
-- Telemetry
--------------------------------------------------

local function updateTelemetry()

    if not thruster then
        return
    end

    local ok, value

    ok, value =
        pcall(
            thruster.getVectorX
        )

    if ok and value ~= nil then
        state.thruster.vectorX =
            value
    end

    ok, value =
        pcall(
            thruster.getVectorY
        )

    if ok and value ~= nil then
        state.thruster.vectorY =
            value
    end

    ok, value =
        pcall(
            thruster.getTargetVectorX
        )

    if ok and value ~= nil then
        state.thruster.targetVectorX =
            value
    end

    ok, value =
        pcall(
            thruster.getTargetVectorY
        )

    if ok and value ~= nil then
        state.thruster.targetVectorY =
            value
    end

    ok, value =
        pcall(
            thruster.getPower
        )

    if ok and value ~= nil then
        state.thruster.power =
            value
    end

    ok, value =
        pcall(
            thruster.getThrust
        )

    if ok and value ~= nil then
        state.thruster.thrust =
            value
    end
end

--------------------------------------------------
-- Set neutral position
--------------------------------------------------

local function setNeutral()

    if not thruster then
        return
    end

    pcall(
        thruster.setVector,
        0,
        0
    )

    state.thruster.targetVectorX =
        0

    state.thruster.targetVectorY =
        0
end

--------------------------------------------------
-- Apply guidance command
--------------------------------------------------

local function updateCommand()

    if not thruster then
        return
    end

    --------------------------------------------------
    -- CONTROL DISABLED
    --------------------------------------------------

    if not state.system.controlEnabled then

        setNeutral()

        return
    end

    --------------------------------------------------
    -- GUIDANCE OFFLINE
    --------------------------------------------------

    if not state.guidance
        or not state.guidance.online then

        setNeutral()

        return
    end

    --------------------------------------------------
    -- GUIDANCE NOT ACTIVE
    --------------------------------------------------

    if not state.guidance.active then

        setNeutral()

        return
    end

    --------------------------------------------------
    -- Read guidance commands
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
    -- Send vector command
    --------------------------------------------------

    pcall(
        thruster.setVector,
        x,
        y
    )
end

--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run()

    --------------------------------------------------
    -- Thruster unavailable
    --------------------------------------------------

    if not thruster then

        state.thruster.online =
            false

        state.thruster.status =
            "OFFLINE"

        while state.system.running do
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
    -- Safety: start neutral
    --------------------------------------------------

    setNeutral()

    --------------------------------------------------
    -- Main actuator loop
    --------------------------------------------------

    while state.system.running do

        updateCommand()

        updateTelemetry()

        sleep(0.05)
    end

    --------------------------------------------------
    -- Safety shutdown
    --------------------------------------------------

    setNeutral()

    state.thruster.vectorX =
        0

    state.thruster.vectorY =
        0

    state.thruster.targetVectorX =
        0

    state.thruster.targetVectorY =
        0

    state.thruster.online =
        false

    state.thruster.status =
        "OFFLINE"
end

return {
    run = run
}