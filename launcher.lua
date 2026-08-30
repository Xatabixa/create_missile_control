-- Missile Control System Launcher
-- All modules share the same state and require function.

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local BASE = "/rocket"

--------------------------------------------------
-- LOAD STATE
--------------------------------------------------

local stateChunk, stateError =
    loadfile(BASE .. "/state.lua")

if not stateChunk then

    error(
        "STATE LOAD ERROR:\n" ..
        tostring(stateError)
    )

end

local state =
    stateChunk()

--------------------------------------------------
-- MODULE LOADER
--------------------------------------------------

local function loadModule(filename)

    local path =
        BASE .. "/" .. filename

    if not fs.exists(path) then

        error(
            "MODULE FILE NOT FOUND:\n" ..
            path
        )

    end

    local handle =
        fs.open(path, "r")

    if not handle then

        error(
            "CANNOT OPEN MODULE:\n" ..
            path
        )

    end

    local source =
        handle.readAll()

    handle.close()

    --------------------------------------------------
    -- MODULE ENVIRONMENT
    --------------------------------------------------

    local env = {}

    setmetatable(
        env,
        {
            __index = _G
        }
    )

    --------------------------------------------------
    -- SHARED REQUIRE
    --------------------------------------------------

    env.require = function(name)

        if name == "state" then
            return state
        end

        error(
            "Unknown module requested: " ..
            tostring(name)
        )

    end

    --------------------------------------------------
    -- COMPILE
    --------------------------------------------------

    local chunk, err =
        load(
            source,
            "@" .. path,
            "t",
            env
        )

    if not chunk then

        error(
            "COMPILE ERROR:\n" ..
            path ..
            "\n\n" ..
            tostring(err)
        )

    end

    return chunk

end

--------------------------------------------------
-- INITIAL STATE
--------------------------------------------------

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

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

    local ok, err =
        xpcall(
            module,
            debug.traceback
        )

    if not ok then

        state.system.status = "ERROR"
        state.system.running = false

        term.clear()
        term.setCursorPos(1, 1)

        print("MISSILE CONTROL ERROR")
        print("=====================")
        print("")
        print("MODULE:")
        print(name)
        print("")
        print("ERROR:")
        print(tostring(err))
        print("")
        print("Press any key...")

        os.pullEvent("key")

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