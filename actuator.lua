-- Actuator subsystem.
--
-- This is the only subsystem allowed to write vector commands
-- to the propulsion peripheral.
--
-- Shutdown ALWAYS resets the vector to zero.

local state = ...

local thruster = nil
local thrusterType = "NONE"

--------------------------------------------------
-- FIND THRUSTER
--------------------------------------------------

local function findThruster()

    local peripheralObject

    peripheralObject =
        peripheral.find(
            "liquid_vector_thruster"
        )

    if peripheralObject then

        return peripheralObject,
            "LIQUID_VECTOR"

    end

    peripheralObject =
        peripheral.find(
            "vector_thruster"
        )

    if peripheralObject then

        return peripheralObject,
            "VECTOR"

    end

    peripheralObject =
        peripheral.find(
            "creative_vector_thruster"
        )

    if peripheralObject then

        return peripheralObject,
            "CREATIVE_VECTOR"

    end

    return nil, "NONE"
end

--------------------------------------------------
-- VECTOR
--------------------------------------------------

local function setVector(
    x,
    y
)

    if not thruster then
        return false
    end

    --------------------------------------------------
    -- Combined API
    --------------------------------------------------

    if type(
        thruster.setVector
    ) == "function" then

        local ok =
            pcall(
                function()

                    thruster.setVector(
                        x,
                        y
                    )

                end
            )

        return ok
    end

    --------------------------------------------------
    -- Separate API
    --------------------------------------------------

    local xOK = true
    local yOK = true

    if type(
        thruster.setVectorX
    ) == "function" then

        xOK =
            pcall(
                function()

                    thruster.setVectorX(x)

                end
            )
    end

    if type(
        thruster.setVectorY
    ) == "function" then

        yOK =
            pcall(
                function()

                    thruster.setVectorY(y)

                end
            )
    end

    return xOK and yOK
end

--------------------------------------------------
-- THROTTLE
--------------------------------------------------

local function setPower(power)

    if not thruster then
        return
    end

    if type(
        thruster.setPowerNormalized
    ) == "function" then

        pcall(
            function()

                thruster.setPowerNormalized(
                    power
                )

            end
        )

        return
    end

    if type(
        thruster.setThrustNormalized
    ) == "function" then

        pcall(
            function()

                thruster.setThrustNormalized(
                    power
                )

            end
        )

        return
    end

    if type(
        thruster.setPower
    ) == "function" then

        pcall(
            function()

                thruster.setPower(
                    math.floor(
                        power * 15
                        + 0.5
                    )
                )

            end
        )
    end
end

--------------------------------------------------
-- TELEMETRY
--------------------------------------------------

local function readTelemetry()

    if not thruster then

        state.actuator.online =
            false

        state.actuator.status =
            "OFFLINE"

        state.actuator.type =
            "NONE"

        return
    end

    state.actuator.online =
        true

    state.actuator.type =
        thrusterType

    --------------------------------------------------
    -- VECTOR X
    --------------------------------------------------

    if type(
        thruster.getVectorX
    ) == "function" then

        local ok, value =
            pcall(
                function()

                    return thruster.getVectorX()

                end
            )

        if ok and value ~= nil then

            state.actuator.vectorX =
                value

        end
    end

    --------------------------------------------------
    -- VECTOR Y
    --------------------------------------------------

    if type(
        thruster.getVectorY
    ) == "function" then

        local ok, value =
            pcall(
                function()

                    return thruster.getVectorY()

                end
            )

        if ok and value ~= nil then

            state.actuator.vectorY =
                value

        end
    end

    --------------------------------------------------
    -- POWER
    --------------------------------------------------

    if type(
        thruster.getPower
    ) == "function" then

        local ok, value =
            pcall(
                function()

                    return thruster.getPower()

                end
            )

        if ok and value ~= nil then

            state.actuator.power =
                value

        end
    end

    --------------------------------------------------
    -- THRUST
    --------------------------------------------------

    if type(
        thruster.getCurrentThrustKN
    ) == "function" then

        local ok, value =
            pcall(
                function()

                    return thruster.getCurrentThrustKN()

                end
            )

        if ok and value ~= nil then

            state.actuator.thrust =
                value

        end
    end

    state.actuator.lastUpdate =
        os.clock()

    state.actuator.updateCount =
        state.actuator.updateCount + 1
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    thruster, thrusterType =
        findThruster()

    if not thruster then

        state.actuator.online =
            false

        state.actuator.status =
            "OFFLINE"

        state.actuator.type =
            "NONE"

        return
    end

    --------------------------------------------------
    -- CONTROL ENABLED
    --------------------------------------------------

    if state.system.controlEnabled
        and state.navigation.online
        and state.guidance.online
        and state.target.set then

        state.actuator.commandX =
            state.guidance.commandX

        state.actuator.commandY =
            state.guidance.commandY

        setVector(
            state.guidance.commandX,
            state.guidance.commandY
        )

    else

        state.actuator.commandX = 0
        state.actuator.commandY = 0

        setVector(0, 0)

    end

    state.actuator.status =
        state.system.controlEnabled
        and "ACTIVE"
        or "MONITOR"

    readTelemetry()
end

--------------------------------------------------
-- INIT
--------------------------------------------------

function init()

    thruster, thrusterType =
        findThruster()

end

--------------------------------------------------
-- LOOP
--------------------------------------------------

function run()

    while state.system.running do

        update()

        sleep(0.05)

    end

    shutdown()
end

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

function shutdown()

    if not thruster then

        thruster, thrusterType =
            findThruster()

    end

    -- ALWAYS zero vector.

    setVector(
        0,
        0
    )

    -- ALWAYS zero throttle.

    setPower(0)

    state.actuator.commandX = 0
    state.actuator.commandY = 0

    state.actuator.vectorX = 0
    state.actuator.vectorY = 0

    state.actuator.power = 0

    state.actuator.online =
        false

    state.actuator.status =
        "OFFLINE"
end