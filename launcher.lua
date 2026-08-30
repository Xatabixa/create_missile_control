-- Missile Control System Launcher
-- Simple CC:Tweaked launcher.
-- All modules are executed as normal ComputerCraft programs.

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local ROOT = "/rocket"

local modules = {
    "navigation.lua",
    "guidance.lua",
    "actuator.lua",
    "display.lua"
}

--------------------------------------------------
-- PREPARE ENVIRONMENT
--------------------------------------------------

-- Make /rocket the working directory.
shell.setDir(ROOT)

--------------------------------------------------
-- CHECK FILES
--------------------------------------------------

for _, file in ipairs(modules) do

    local path =
        ROOT .. "/" .. file

    if not fs.exists(path) then

        term.clear()
        term.setCursorPos(1, 1)

        print("MISSILE CONTROL")
        print("================")
        print("")
        print("FILE NOT FOUND:")
        print(path)
        print("")
        print("Press any key...")

        os.pullEvent("key")

        return
    end
end

--------------------------------------------------
-- START SYSTEM
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("MISSILE CONTROL")
print("================")
print("")
print("Starting systems...")
print("")

sleep(0.5)

--------------------------------------------------
-- RUN MODULES
--------------------------------------------------

parallel.waitForAll(

    function()
        shell.run(ROOT .. "/navigation.lua")
    end,

    function()
        shell.run(ROOT .. "/guidance.lua")
    end,

    function()
        shell.run(ROOT .. "/actuator.lua")
    end,

    function()
        shell.run(ROOT .. "/display.lua")
    end

)

--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("MISSILE CONTROL")
print("================")
print("")
print("SYSTEM STOPPED")
print("")
print("Press any key...")

os.pullEvent("key")