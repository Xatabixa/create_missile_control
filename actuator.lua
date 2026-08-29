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

    while state.system.running do
        sleep(1)
    end

    return
end

state.thruster.online = true

--------------------------------------------------
-- UPDATE
--------------------------------------------------

local function update()

    local x =
        state.guidance.commandX or 0

    local y =
        state.guidance.commandY or 0

    thruster.setVector(x, y)

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