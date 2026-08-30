-- Missile Control System Launcher

local state = require("state")
local navigation = require("navigation")
local guidance = require("guidance")
local actuator = require("actuator")
local display = require("display")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"
state.system.error = nil

local function fail(name, err)
    state.system.error = name .. ": " .. tostring(err)
    state.system.status = "FAULT"
    state.system.running = false
end

local function protected(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        fail(name, err)
        error(name .. ": " .. tostring(err), 0)
    end
end

term.clear()
term.setCursorPos(1, 1)
print("================================")
print("       MISSILE CONTROL")
print("================================")
print("")
print("Starting systems...")
print("")

parallel.waitForAll(
    function() protected("NAVIGATION", navigation.run) end,
    function() protected("GUIDANCE", guidance.run) end,
    function() protected("ACTUATOR", actuator.run) end,
    function() protected("DISPLAY", display.run) end
)

state.system.running = false
state.system.status = "STOPPED"
state.system.controlEnabled = false

term.clear()
term.setCursorPos(1, 1)
print("MISSILE SYSTEM STOPPED")
