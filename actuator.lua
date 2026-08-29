-- Thruster actuator
-- The only module allowed to control the vector thruster.
--
-- SAFETY:
-- Thrust is permanently disabled.

local state = require("state")

--------------------------------------------------
-- FIND THRUSTER
--------------------------------------------------

local thruster =
    peripheral.find("liquid_vector_thruster")

if not thruster then

    state.thruster.online = false

    while true do
        sleep(1)
    end

end

state.thruster.online = true

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    --------------------------------------------------
    -- FORCE THRUST OFF
    --------------------------------------------------

    thruster.setThrustNormalized(0)

    --------------------------------------------------
    -- GET GUIDANCE COMMAND
    --------------------------------------------------

    local x =
        state.guidance.commandX

    local y =
        state.guidance.commandY

    --------------------------------------------------
    -- COMMAND COMPLETE VECTOR
    --------------------------------------------------

    thruster.setVector(
        x,
        y
    )

    --------------------------------------------------
    -- READ RESPONSE
    --------------------------------------------------

    state.thruster.vectorX =
        thruster.getVectorX()

    state.thruster.vectorY =
        thruster.getVectorY()

    state.thruster.targetVectorX =
        thruster.getTargetVectorX()

    state.thruster.targetVectorY =
        thruster.getTargetVectorY()

    state.thruster.power =
        thruster.getPower()

    state.thruster.thrust =
        thruster.getThrust()

end

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while state.system.running do

    update()

    sleep(0.05)

end

-- Safety shutdown
thruster.setVector(0, 0)
thruster.setThrustNormalized(0)