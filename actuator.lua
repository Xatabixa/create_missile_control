-- Liquid Vector Thruster actuator
-- DRY TEST mode only reads telemetry.
-- No steering command is sent to the thruster.

local state = require("state")

--------------------------------------------------
-- FIND THRUSTER
--------------------------------------------------

local thruster =
    peripheral.find("liquid_vector_thruster")

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

--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function call(method)

    if not thruster[method] then
        return nil
    end

    local ok, result =
        pcall(
            thruster[method]
        )

    if not ok then
        return nil
    end

    return result
end

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    --------------------------------------------------
    -- POWER
    --------------------------------------------------

    local power =
        call("getPower")

    if power ~= nil then

        state.thruster.power =
            power

    end

    --------------------------------------------------
    -- THRUST
    --------------------------------------------------

    local thrust =
        call("getThrust")

    if thrust ~= nil then

        state.thruster.thrust =
            thrust

    end

    --------------------------------------------------
    -- ACTUAL VECTOR
    --------------------------------------------------

    local vectorX =
        call("getVectorX")

    if vectorX ~= nil then

        state.thruster.vectorX =
            vectorX

    end

    local vectorY =
        call("getVectorY")

    if vectorY ~= nil then

        state.thruster.vectorY =
            vectorY

    end

    --------------------------------------------------
    -- TARGET VECTOR
    --------------------------------------------------

    local targetVectorX =
        call("getTargetVectorX")

    if targetVectorX ~= nil then

        state.thruster.targetVectorX =
            targetVectorX

    end

    local targetVectorY =
        call("getTargetVectorY")

    if targetVectorY ~= nil then

        state.thruster.targetVectorY =
            targetVectorY

    end

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    state.thruster.online = true
    state.thruster.status = "ONLINE"

    state.thruster.updateCount =
        state.thruster.updateCount + 1

    state.thruster.lastUpdate =
        os.clock()

end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    update()

    sleep(0.05)

end

state.thruster.online = false
state.thruster.status = "OFFLINE"