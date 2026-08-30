-- Missile Control System Launcher
-- Runs all modules in the same environment.
-- Module errors are reported instead of being silently hidden.

--------------------------------------------------
-- LOAD SHARED STATE
--------------------------------------------------

local state = require("state")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

--------------------------------------------------
-- MODULE LOADER
--------------------------------------------------

local function loadModule(filename)

    local chunk, errorMessage =
        loadfile(filename)

    if not chunk then

        error(
            "LOAD ERROR [" ..
            filename ..
            "]: " ..
            tostring(errorMessage)
        )

    end

    return chunk

end

--------------------------------------------------
-- MODULES
--------------------------------------------------

local modules = {

    {
        name = "NAVIGATION",
        file = "navigation.lua"
    },

    {
        name = "GUIDANCE",
        file = "guidance.lua"
    },

    {
        name = "THRUSTER",
        file = "actuator.lua"
    },

    {
        name = "DISPLAY",
        file = "display.lua"
    }

}

--------------------------------------------------
-- LOAD ALL MODULES
--------------------------------------------------

local loaded = {}

for _, module in ipairs(modules) do

    loaded[module.name] =
        loadModule(module.file)

end

--------------------------------------------------
-- RUN MODULE
--------------------------------------------------

local function runModule(name)

    local ok, errorMessage =
        pcall(
            loaded[name]
        )

    if not ok then

        state.system.status = "ERROR"

        print("")
        print("==============================")
        print("MODULE ERROR")
        print(name)
        print("==============================")
        print("")
        print(tostring(errorMessage))
        print("")

        state.system.running = false

    end

end

--------------------------------------------------
-- START
--------------------------------------------------

state.system.status = "ONLINE"

parallel.waitForAny(

    function()
        runModule("NAVIGATION")
    end,

    function()
        runModule("GUIDANCE")
    end,

    function()
        runModule("THRUSTER")
    end,

    function()
        runModule("DISPLAY")
    end

)

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

state.system.running = false

if state.system.status ~= "ERROR" then
    state.system.status = "OFFLINE"
end