-- Vector thruster actuator

local state = require("state")

local thruster = peripheral.find("vector_thruster")
    or peripheral.find("liquid_vector_thruster")

local function updateTelemetry()
    if not thruster then return end

    local ok, value = pcall(thruster.getVectorX)
    if ok and value ~= nil then state.thruster.vectorX = value end

    ok, value = pcall(thruster.getVectorY)
    if ok and value ~= nil then state.thruster.vectorY = value end

    ok, value = pcall(thruster.getTargetVectorX)
    if ok and value ~= nil then state.thruster.targetVectorX = value end

    ok, value = pcall(thruster.getTargetVectorY)
    if ok and value ~= nil then state.thruster.targetVectorY = value end

    ok, value = pcall(thruster.getPower)
    if ok and value ~= nil then state.thruster.power = value end

    ok, value = pcall(thruster.getThrust)
    if ok and value ~= nil then state.thruster.thrust = value end
end

local function updateCommand()
    if not thruster then return end

    local x = math.max(-1, math.min(1, state.guidance.commandX or 0))
    local y = math.max(-1, math.min(1, state.guidance.commandY or 0))

    pcall(thruster.setVector, x, y)
end

local function run()
    if not thruster then
        state.thruster.online = false
        state.thruster.status = "OFFLINE"

        while state.system.running do
            sleep(1)
        end

        return
    end

    state.thruster.online = true
    state.thruster.status = "ONLINE"

    while state.system.running do
        updateCommand()
        updateTelemetry()
        sleep(0.05)
    end

    pcall(thruster.setVector, 0, 0)

    state.thruster.vectorX = 0
    state.thruster.vectorY = 0
    state.thruster.targetVectorX = 0
    state.thruster.targetVectorY = 0
    state.thruster.online = false
    state.thruster.status = "OFFLINE"
end

return { run = run }
