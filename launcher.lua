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

-- Load shared state
local state = dofile("state.lua")

if type(state) ~= "table" then
    error("STATE MODULE INVALID")
end

-- Load module
local function loadModule(filename)
    local chunk, err = loadfile(filename)

    if not chunk then
        error("LOAD ERROR " .. filename .. ": " .. tostring(err))
    end

    local ok, result = pcall(chunk)

    if not ok then
        error("MODULE ERROR " .. filename .. ": " .. tostring(result))
    end

    if type(result) ~= "table" then
        error("MODULE RETURN ERROR " .. filename)
    end

    return result
end

local navigation = loadModule("navigation.lua")
local guidance = loadModule("guidance.lua")
local actuator = loadModule("actuator.lua")
local display = loadModule("display.lua")

if type(navigation.run) ~= "function" then
    error("NAVIGATION MODULE INVALID")
end

if type(guidance.run) ~= "function" then
    error("GUIDANCE MODULE INVALID")
end

if type(actuator.run) ~= "function" then
    error("ACTUATOR MODULE INVALID")
end

if type(display.run) ~= "function" then
    error("DISPLAY MODULE INVALID")
end

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "ONLINE"
state.system.controlEnabled = false
state.system.error = nil

print("STATE ............ OK")
print("NAVIGATION ....... OK")
print("GUIDANCE ......... OK")
print("ACTUATOR ......... OK")
print("DISPLAY .......... OK")
print("")
print("Starting systems...")
print("")

local function runNavigation()
    local ok, err = pcall(
        navigation.run,
        state
    )

    if not ok then
        state.system.error =
            "NAVIGATION: " .. tostring(err)

        state.system.status = "FAULT"
        state.system.running = false

        print(state.system.error)
    end
end

local function runGuidance()
    local ok, err = pcall(
        guidance.run,
        state
    )

    if not ok then
        state.system.error =
            "GUIDANCE: " .. tostring(err)

        state.system.status = "FAULT"
        state.system.running = false

        print(state.system.error)
    end
end

local function runActuator()
    local ok, err = pcall(
        actuator.run,
        state
    )

    if not ok then
        state.system.error =
            "ACTUATOR: " .. tostring(err)

        state.system.status = "FAULT"
        state.system.running = false

        print(state.system.error)
    end
end

local function runDisplay()
    local ok, err = pcall(
        display.run,
        state
    )

    if not ok then
        state.system.error =
            "DISPLAY: " .. tostring(err)

        state.system.status = "FAULT"
        state.system.running = false

        print(state.system.error)
    end
end

parallel.waitForAll(
    function()
        runModule("NAVIGATION", function()
            navigation.run(state)
        end)
    end,

    function()
        runModule("GUIDANCE", function()
            guidance.run(state)
        end)
    end,

    function()
        runModule("ACTUATOR", function()
            actuator.run(state)
        end)
    end,

    function()
        runModule("DISPLAY", function()
            display.run(state)
        end)
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

if state.system.error then
    print("")
    print("ERROR:")
    print(state.system.error)
end