-- Missile Control System
-- Main launcher

--------------------------------------------------
-- LOAD SHARED STATE
--------------------------------------------------

local state =
    require("state")

--------------------------------------------------
-- MODULES
--------------------------------------------------

local modules = {

    "navigation",
    "guidance",
    "actuator",
    "display"
}

--------------------------------------------------
-- RUN MODULE
--------------------------------------------------

local function runModule(name)

    shell.run(
        name .. ".lua"
    )

end

--------------------------------------------------
-- START SYSTEM
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("   MISSILE CONTROL SYSTEM")
print("================================")
print("")
print("Starting subsystems...")
print("")

sleep(1)

--------------------------------------------------
-- PARALLEL EXECUTION
--------------------------------------------------

parallel.waitForAny(

    function()

        runModule(
            "navigation"
        )

    end,

    function()

        runModule(
            "guidance"
        )

    end,

    function()

        runModule(
            "actuator"
        )

    end,

    function()

        runModule(
            "display"
        )

    end

)

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

state.system.running = false

term.clear()
term.setCursorPos(1, 1)

print("Missile Control System stopped.")