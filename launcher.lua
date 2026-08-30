-- Missile Control Master Launcher
--
-- This program owns the shared state and starts all subsystems
-- concurrently.
--
-- Shutdown of state.system.running causes every subsystem to stop.

local STATE_FILE = "state.lua"
local TARGET_FILE = "target.cfg"

--------------------------------------------------
-- LOAD SHARED STATE
--------------------------------------------------

local state = dofile(STATE_FILE)

_G.MISSILE_STATE = state

--------------------------------------------------
-- LOAD TARGET
--------------------------------------------------

local function loadTarget()

    if not fs.exists(TARGET_FILE) then
        state.target.set = false
        return
    end

    local file = fs.open(TARGET_FILE, "r")

    if not file then
        state.target.set = false
        return
    end

    local text = file.readAll()
    file.close()

    local data = textutils.unserialize(text)

    if type(data) ~= "table" then
        state.target.set = false
        return
    end

    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)

    if x and y and z then

        state.target.x = x
        state.target.y = y
        state.target.z = z

        state.target.set = data.set ~= false

        state.target.revision =
            tonumber(data.revision) or 0

    else
        state.target.set = false
    end
end

loadTarget()

--------------------------------------------------
-- MODULE LOADER
--------------------------------------------------

local function loadModule(filename)

    local chunk, err = loadfile(filename)

    if not chunk then
        error(
            "LOAD ERROR [" ..
            filename ..
            "]: " ..
            tostring(err)
        )
    end

    local ok, module = pcall(chunk, state)

    if not ok then
        error(
            "INIT ERROR [" ..
            filename ..
            "]: " ..
            tostring(module)
        )
    end

    if type(module) ~= "table" then
        error(
            "MODULE [" ..
            filename ..
            "] DID NOT RETURN A TABLE"
        )
    end

    if type(module.init) == "function" then

        local initOK, initError =
            pcall(module.init)

        if not initOK then

            error(
                "MODULE INIT ERROR [" ..
                filename ..
                "]: " ..
                tostring(initError)
            )

        end
    end

    return module
end

--------------------------------------------------
-- LOAD ALL SYSTEMS
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
-- SYSTEM STATE
--------------------------------------------------

state.system.running = true
state.system.status = "ONLINE"
state.system.mode = "STANDBY"

--------------------------------------------------
-- SAFE MODULE RUNNER
--------------------------------------------------

local function runModule(name, module)

    local ok, err =
        pcall(module.run)

    if not ok then

        state.system.error =
            name .. ": " .. tostring(err)

        state.system.status = "ERROR"

        state.system.running = false
    end
end

--------------------------------------------------
-- RUN ALL SYSTEMS SIMULTANEOUSLY
--------------------------------------------------

parallel.waitForAll(

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
-- GLOBAL SHUTDOWN
--------------------------------------------------

state.system.running = false

state.system.status =
    state.system.status == "ERROR"
    and "ERROR"
    or "OFFLINE"

--------------------------------------------------
-- HARD ACTUATOR SHUTDOWN
--------------------------------------------------

if type(actuator.shutdown) == "function" then

    pcall(
        actuator.shutdown
    )

end