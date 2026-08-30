-- Vector thruster actuator
-- Single-folder ComputerCraft compatible version

local thruster =
    peripheral.find("vector_thruster")
    or peripheral.find("liquid_vector_thruster")

local function run(state)

    local function updateTelemetry()

        if not thruster then
            return
        end

        local ok, value =
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

    local function setVector(x, y)

        if not thruster then
            return
        end

        x =
            math.max(
                -1,
                math.min(1, x)
            )

        y =
            math.max(
                -1,
                math.min(1, y)
            )

        pcall(
            thruster.setVector,
            x,
            y
        )
    end

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

    state.thruster.online =
        true

    state.thruster.status =
        "ONLINE"

    while state.system.running do

        if state.system.controlEnabled
            and state.guidance.active then

            setVector(
                state.guidance.commandX or 0,
                state.guidance.commandY or 0
            )

        else

            setVector(0, 0)
        end

        updateTelemetry()

        sleep(0.05)
    end

    setVector(0, 0)

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