-- Liquid Vector Thruster actuator
-- Reads real thruster telemetry.
-- Does not control the thruster during DRY TEST.

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
state.thruster.status = "DRY TEST"

--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function call(method)

    if not thruster[method] then
        return nil
    end

    local ok, result =
        pcall(thruster[method])

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

    local targetX =
        call("getTargetVectorX")

    if targetX ~= nil then
        state.thruster.targetVectorX =
            targetX
    end

    local targetY =
        call("getTargetVectorY")

    if targetY ~= nil then
        state.thruster.targetVectorY =
            targetY
    end

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    state.thruster.online = true
    state.thruster.status = "DRY TEST"

    state.thruster.lastUpdate =
        os.clock()

    state.thruster.updateCount =
        state.thruster.updateCount + 1
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