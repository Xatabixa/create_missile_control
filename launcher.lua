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

term.clear()
term.setCursorPos(1, 1)
print("================================")
print("       MISSILE CONTROL")
print("================================")
print("")
print("Starting systems...")
print("")

local function runModule(name, fn)
    local ok, err = pcall(fn)
    if not ok then
        state.system.error = name .. ": " .. tostring(err)
        state.system.status = "FAULT"
        state.system.running = false
        error(state.system.error, 0)
    end
end

state.system.status = "ONLINE"

parallel.waitForAll(
    function() runModule("NAVIGATION", navigation.run) end,
    function() runModule("GUIDANCE", guidance.run) end,
    function() runModule("ACTUATOR", actuator.run) end,
    function() runModule("DISPLAY", display.run) end
)

state.system.running = false
if state.system.status ~= "FAULT" then
    state.system.status = "STOPPED"
end
state.system.controlEnabled = false

term.clear()
term.setCursorPos(1, 1)
print("MISSILE SYSTEM STOPPED")
