-- Missile Control System Launcher

local state = require("state")

state.system.running = true
state.system.mode = "DRY TEST"

--------------------------------------------------
-- MODULES
--------------------------------------------------

local function runNavigation()

    shell.run("navigation.lua")

end

local function runGuidance()

    shell.run("guidance.lua")

end

local function runActuator()

    shell.run("actuator.lua")

end

local function runDisplay()

    shell.run("display.lua")

end

--------------------------------------------------
-- RUN
--------------------------------------------------

parallel.waitForAll(

    runNavigation,
    runGuidance,
    runActuator,
    runDisplay

)

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

state.system.running = false

term.clear()
term.setCursorPos(1, 1)

print("MISSILE SYSTEM STOPPED")