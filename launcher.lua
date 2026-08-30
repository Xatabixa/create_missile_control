-- Missile Control System Launcher

local state = require("state")

state.system.running = true
state.system.mode = "DRY TEST"

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("       MISSILE CONTROL")
print("================================")
print("")
print("Starting systems...")
print("")

local function runNavigation()
    local ok, err = pcall(function()
        shell.run("navigation.lua")
    end)

    if not ok then
        state.system.running = false
        error("NAVIGATION ERROR: " .. tostring(err))
    end
end

local function runGuidance()
    local ok, err = pcall(function()
        shell.run("guidance.lua")
    end)

    if not ok then
        state.system.running = false
        error("GUIDANCE ERROR: " .. tostring(err))
    end
end

local function runActuator()
    local ok, err = pcall(function()
        shell.run("actuator.lua")
    end)

    if not ok then
        state.system.running = false
        error("ACTUATOR ERROR: " .. tostring(err))
    end
end

local function runDisplay()
    local ok, err = pcall(function()
        shell.run("display.lua")
    end)

    if not ok then
        state.system.running = false
        error("DISPLAY ERROR: " .. tostring(err))
    end
end

parallel.waitForAll(
    runNavigation,
    runGuidance,
    runActuator,
    runDisplay
)

state.system.running = false

term.clear()
term.setCursorPos(1, 1)

print("MISSILE SYSTEM STOPPED")