-- Vector thruster actuator
-- Automatic TVC control

local thruster =
    peripheral.find("vector_thruster")
    or peripheral.find("liquid_vector_thruster")

local function safeCall(object, method, ...)
    if not object then
        return nil
    end

    local fn = object[method]

    if type(fn) ~= "function" then
        return nil
    end

    local ok, value = pcall(fn, ...)

    if ok then
        return value
    end

    return nil
end

local function updateTelemetry(state)
    if not thruster then
        return
    end

    local value =
        safeCall(thruster, "getVectorX")

    if value ~= nil then
        state.thruster.vectorX = value
    end

    value =
        safeCall(thruster, "getVectorY")

    if value ~= nil then
        state.thruster.vectorY = value
    end

    value =
        safeCall(thruster, "getTargetVectorX")

    if value ~= nil then
        state.thruster.targetVectorX = value
    end

    value =
        safeCall(thruster, "getTargetVectorY")

    if value ~= nil then
        state.thruster.targetVectorY = value
    end

    value =
        safeCall(thruster, "getPower")

    if value ~= nil then
        state.thruster.power = value
    end

    value =
        safeCall(thruster, "getThrust")

    if value ~= nil then
        state.thruster.thrust = value
    end
end

local function setVector(state, x, y)
    if not thruster then
        return
    end

    x = math.max(-1, math.min(1, x))
    y = math.max(-1, math.min(1, y))

    pcall(thruster.setVector, x, y)
end

local function run(state)
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

        if state.system.controlEnabled
            and state.guidance.active then

            setVector(
                state,
                state.guidance.commandX or 0,
                state.guidance.commandY or 0
            )

        else
            setVector(state, 0, 0)
        end

        updateTelemetry(state)

        sleep(0.05)
    end

    setVector(state, 0, 0)

    state.thruster.vectorX = 0
    state.thruster.vectorY = 0
    state.thruster.targetVectorX = 0
    state.thruster.targetVectorY = 0

    state.thruster.online = false
    state.thruster.status = "OFFLINE"
end

return {
    run = run
}