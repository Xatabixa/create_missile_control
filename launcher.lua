-- Missile Control System Launcher
-- All modules run inside the same Lua environment
-- so they share the same state table.

--------------------------------------------------
-- LOAD SHARED STATE
--------------------------------------------------

local state = require("state")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

--------------------------------------------------
-- LOAD MODULE
--------------------------------------------------

local function loadModule(filename)

    local chunk, errorMessage =
        loadfile(filename)

    if not chunk then

        error(
            "Failed to load " ..
            filename ..
            ": " ..
            tostring(errorMessage)
        )

    end

    return chunk
end

--------------------------------------------------
-- LOAD ALL MODULES
--------------------------------------------------

local navigation =
    loadModule("navigation.lua")

local guidance =
    loadModule("guidance.lua")

local actuator =
    loadModule("actuator.lua")

local display =
    loadModule("display.lua")

--------------------------------------------------
-- RUN MODULE
--------------------------------------------------

local function runModule(name, module)

    local ok, errorMessage =
        pcall(module)

    if not ok then

        print("")
        print("MODULE ERROR")
        print(name)
        print("")
        print(tostring(errorMessage))

        state.system.status = "ERROR"

        state.system.running = false

    end

end

--------------------------------------------------
-- START SYSTEM
--------------------------------------------------

parallel.waitForAny(

    function()
        runModule(
            "NAVIGATION",
            navigation
        )
    end,

    function()
        runModule(
            "GUIDANCE",
            guidance
        )
    end,

    function()
        runModule(
            "ACTUATOR",
            actuator
        )
    end,

    function()
        runModule(
            "DISPLAY",
            display
        )
    end

)

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

state.system.running = false
state.system.status = "OFFLINE"

term.clear()
term.setCursorPos(1, 1)

print("MISSILE CONTROL SYSTEM")
print("======================")
print("")
print("SYSTEM OFFLINE")