-- Missile Control System Launcher
-- Uses the directory of launcher.lua as the module directory.

--------------------------------------------------
-- FIND LAUNCHER DIRECTORY
--------------------------------------------------

local programPath =
    shell.getRunningProgram()

local baseDir =
    fs.getDir(programPath)

if baseDir == "" then
    baseDir = "/"
end

if string.sub(baseDir, 1, 1) ~= "/" then
    baseDir = "/" .. baseDir
end

--------------------------------------------------
-- USE ROCKET DIRECTORY
--------------------------------------------------

shell.setDir(baseDir)

--------------------------------------------------
-- LOAD SHARED STATE
--------------------------------------------------

local state =
    require("state")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

--------------------------------------------------
-- MODULE LOADER
--------------------------------------------------

local function loadModule(filename)

    local path =
        fs.combine(baseDir, filename)

    if not fs.exists(path) then

        error(
            "MODULE NOT FOUND: " ..
            path
        )

    end

    local chunk, errorMessage =
        loadfile(path)

    if not chunk then

        error(
            "LOAD ERROR [" ..
            path ..
            "]: " ..
            tostring(errorMessage)
        )

    end

    return chunk
end

--------------------------------------------------
-- LOAD MODULES
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
            "THRUSTER",
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

if state.system.status ~= "ERROR" then
    state.system.status = "OFFLINE"
end
