-- Vector thruster actuator

local state = require("state")

--------------------------------------------------
-- FIND THRUSTER
--------------------------------------------------

local thruster =
    peripheral.find("vector_thruster")

--------------------------------------------------
-- OFFLINE
--------------------------------------------------

if not thruster then

    state.thruster.online = false

    while state.system.running do
        sleep(1)
    end

    return
end

state.thruster.online = true

--------------------------------------------------
-- UPDATE TELEMETRY
--------------------------------------------------

local function updateTelemetry()

    local ok, value

    ok, value =
        pcall(
            thruster.getVectorX
        )

    if ok and value ~= nil then
        state.thruster.vectorX = value
    end

    ok, value =
        pcall(
            thruster.getVectorY
        )

    if ok and value ~= nil then
        state.thruster.vectorY = value
    end

    ok, value =
        pcall(
            thruster.getTargetVectorX
        )

    if ok and value ~= nil then
        state.thruster.targetVectorX = value
    end

    ok, value =
        pcall(
            thruster.getTargetVectorY
        )

    if ok and value ~= nil then
        state.thruster.targetVectorY = value
    end

    ok, value =
        pcall(
            thruster.getPower
        )

    if ok and value ~= nil then
        state.thruster.power = value
    end

    ok, value =
        pcall(
            thruster.getThrust
        )

    if ok and value ~= nil then
        state.thruster.thrust = value
    end
end

--------------------------------------------------
-- APPLY COMMAND
--------------------------------------------------

local function updateCommand()

    local x =
        state.guidance.commandX or 0

    local y =
        state.guidance.commandY or 0

    x = math.max(-1, math.min(1, x))
    y = math.max(-1, math.min(1, y))

    pcall(
        thruster.setVector,
        x,
        y
    )
end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    updateCommand()
    updateTelemetry()

    sleep(0.05)
end

--------------------------------------------------
-- SAFE SHUTDOWN
--------------------------------------------------

pcall(
    thruster.setVector,
    0,
    0
)

state.thruster.vectorX = 0
state.thruster.vectorY = 0

state.thruster.targetVectorX = 0
state.thruster.targetVectorY = 0

state.thruster.online = false