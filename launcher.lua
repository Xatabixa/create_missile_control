-- Missile Control System
-- Main controller

local state = require("state")

--------------------------------------------------
-- STARTUP
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("   MISSILE CONTROL SYSTEM")
print("================================")
print("")
print("Starting subsystems...")
print("")

state.system.running = true
state.system.mode = "DRY TEST"

sleep(1)

--------------------------------------------------
-- MODULE RUNNERS
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
-- RUN EVERYTHING
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

print("================================")
print(" Missile Control System stopped")
print("================================")