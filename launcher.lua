-- Missile Control System Launcher
-- Single-folder ComputerCraft compatible version

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("       MISSILE CONTROL")
print("================================")
print("")
print("Loading control system...")
print("")

-- Load shared state without require()
local state = dofile("state.lua")

-- Load modules and give them access to the same state
local function loadModule(filename)
    local chunk, err = loadfile(filename)

    if not chunk then
        error("LOAD ERROR " .. filename .. ": " .. tostring(err))
    end

    local ok, result = pcall(chunk, state)

    if not ok then
        error("MODULE ERROR " .. filename .. ": " .. tostring(result))
    end

    return result
end

local navigation = loadModule("navigation.lua")
local guidance = loadModule("guidance.lua")
local actuator = loadModule("actuator.lua")
local display = loadModule("display.lua")

if not navigation or type(navigation.run) ~= "function" then
    error("NAVIGATION MODULE INVALID")
end

if not guidance or type(guidance.run) ~= "function" then
    error("GUIDANCE MODULE INVALID")
end

if not actuator or type(actuator.run) ~= "function" then
    error("ACTUATOR MODULE INVALID")
end

if not display or type(display.run) ~= "function" then
    error("DISPLAY MODULE INVALID")
end

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "ONLINE"
state.system.error = nil

print("STATE ............ OK")
print("NAVIGATION ....... LOADED")
print("GUIDANCE ......... LOADED")
print("ACTUATOR ......... LOADED")
print("DISPLAY .......... LOADED")
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

parallel.waitForAll(
    function()
        runModule("NAVIGATION", navigation.run)
    end,

    function()
        runModule("GUIDANCE", guidance.run)
    end,

    function()
        runModule("ACTUATOR", actuator.run)
    end,

    function()
        runModule("DISPLAY", display.run)
    end
)

state.system.running = false
state.system.controlEnabled = false

if state.system.status ~= "FAULT" then
    state.system.status = "STOPPED"
end

term.clear()
term.setCursorPos(1, 1)

print("MISSILE SYSTEM STOPPED")