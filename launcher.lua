-- Missile Control System Launcher
-- Fixed absolute-path version for the /rocket directory.

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local BASE = "/rocket"

--------------------------------------------------
-- FORCE WORKING DIRECTORY
--------------------------------------------------

shell.setDir(BASE)

--------------------------------------------------
-- CONFIGURE REQUIRE PATH
--------------------------------------------------

package.path =
    BASE .. "/?.lua;" ..
    BASE .. "/?/init.lua"

--------------------------------------------------
-- LOAD SHARED STATE
--------------------------------------------------

local state =
    dofile(BASE .. "/state.lua")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

--------------------------------------------------
-- MODULE LOADER
--------------------------------------------------

local function loadModule(filename)

    local path =
        BASE .. "/" .. filename

    -- Explicit filesystem check
    if not fs.exists(path) then

        error(
            "MODULE FILE NOT FOUND:\n" ..
            path
        )

    end

    -- Read the file directly
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

    -- Compile source
    local chunk, err =
        load(
            source,
            "@" .. path,
            "t",
            _ENV
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