-- Missile Control System Launcher

local state = require("state")

--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("MISSILE CONTROL SYSTEM")
print("======================")
print("")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

print("Starting systems...")
print("")

--------------------------------------------------
-- RUN MODULE
--------------------------------------------------

local function runModule(name)

    local ok, err =
        pcall(function()
            shell.run(name)
        end)

    if not ok then

        print("")
        print("MODULE ERROR: " .. name)
        print(tostring(err))

        state.system.status = "ERROR"

        sleep(3)
    end
end

--------------------------------------------------
-- START
--------------------------------------------------

parallel.waitForAll(

    function()
        runModule("navigation.lua")
    end,

    function()
        runModule("guidance.lua")
    end,

    function()
        runModule("actuator.lua")
    end,

    function()
        runModule("display.lua")
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