-- Thruster actuator
-- The only module allowed to control the vector thruster.

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
state.thruster.status = "WAITING"

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    local x =
        state.guidance.commandX or 0

    local y =
        state.guidance.commandY or 0

    --------------------------------------------------
    -- STORE COMMAND
    --------------------------------------------------

    state.thruster.targetVectorX = x
    state.thruster.targetVectorY = y

    --------------------------------------------------
    -- DRY TEST
    --------------------------------------------------

    if state.system.mode == "DRY TEST" then

        state.thruster.vectorX = 0
        state.thruster.vectorY = 0

        state.thruster.power = 0
        state.thruster.thrust = 0

        state.thruster.status = "DRY TEST"

    else

        thruster.setVector(x, y)

        state.thruster.vectorX = x
        state.thruster.vectorY = y

        state.thruster.status = "ACTIVE"

    end

    --------------------------------------------------
    -- UPDATE INFO
    --------------------------------------------------

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

--------------------------------------------------
-- SAFETY SHUTDOWN
--------------------------------------------------

thruster.setVector(0, 0)

state.thruster.vectorX = 0
state.thruster.vectorY = 0
state.thruster.status = "OFFLINE"