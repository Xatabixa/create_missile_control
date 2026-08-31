-- Missile Control System Launcher
-- Single-folder ComputerCraft version
--
-- Modules:
--   state.lua
--   navigation.lua
--   guidance.lua
--   actuator.lua
--   target.lua
--   flight.lua
--   display.lua
--   telemetry_logger.lua
--
-- No require() is used.

--------------------------------------------------
-- STARTUP SCREEN
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("       MISSILE CONTROL")
print("================================")
print("")
print("Loading control system...")
print("")


--------------------------------------------------
-- LOAD STATE
--------------------------------------------------

local stateChunk,
stateError =
    loadfile(
        "state.lua"
    )


if not stateChunk then

    error(
        "STATE LOAD ERROR: " ..
        tostring(
            stateError
        )
    )

end


local ok,
state =
    pcall(
        stateChunk
    )


if not ok then

    error(
        "STATE ERROR: " ..
        tostring(
            state
        )
    )

end


if type(state) ~= "table" then

    error(
        "STATE MODULE INVALID"
    )

end


--------------------------------------------------
-- MODULE LOADER
--------------------------------------------------

local function loadModule(
    filename
)

    local chunk,
    err =
        loadfile(
            filename
        )


    if not chunk then

        error(
            "LOAD ERROR " ..
            filename ..
            ": " ..
            tostring(
                err
            )
        )

    end


    local success,
    module =
        pcall(
            chunk
        )


    if not success then

        error(
            "MODULE ERROR " ..
            filename ..
            ": " ..
            tostring(
                module
            )
        )

    end


    if type(module) ~=
        "table" then

        error(
            "INVALID MODULE " ..
            filename
        )

    end


    if type(module.run) ~=
        "function" then

        error(
            "NO RUN FUNCTION " ..
            filename
        )

    end


    return module

end


--------------------------------------------------
-- LOAD MODULES
--------------------------------------------------

local navigation =
    loadModule(
        "navigation.lua"
    )


local guidance =
    loadModule(
        "guidance.lua"
    )


local actuator =
    loadModule(
        "actuator.lua"
    )


local target =
    loadModule(
        "target.lua"
    )


local flight =
    loadModule(
        "flight.lua"
    )


local display =
    loadModule(
        "display.lua"
    )


--------------------------------------------------
-- TELEMETRY LOGGER
--
-- This module is optional.
--
-- If telemetry_logger.lua exists and loads
-- successfully, it will run alongside the
-- missile-control system.
--
-- If the file does not exist, the main system
-- still starts normally.
--------------------------------------------------

local telemetry = nil

do

    if fs.exists(
        "telemetry_logger.lua"
    ) then

        local telemetryChunk,
        telemetryError =
            loadfile(
                "telemetry_logger.lua"
            )


        if not telemetryChunk then

            error(
                "LOAD ERROR telemetry_logger.lua: " ..
                tostring(
                    telemetryError
                )
            )

        end


        local telemetryOK,
        telemetryModule =
            pcall(
                telemetryChunk
            )


        if not telemetryOK then

            error(
                "MODULE ERROR telemetry_logger.lua: " ..
                tostring(
                    telemetryModule
                )
            )

        end


        if type(
            telemetryModule
        ) ~= "table" then

            error(
                "INVALID MODULE telemetry_logger.lua"
            )

        end


        if type(
            telemetryModule.run
        ) ~= "function" then

            error(
                "NO RUN FUNCTION telemetry_logger.lua"
            )

        end


        telemetry =
            telemetryModule

    end

end


--------------------------------------------------
-- INITIAL SYSTEM STATE
--------------------------------------------------

state.system.running =
    true


state.system.mode =
    "DRY TEST"


state.system.status =
    "STARTING"


state.system.controlEnabled =
    false


state.system.error =
    nil


print("STATE ............ OK")
print("NAVIGATION ....... OK")
print("GUIDANCE ......... OK")
print("ACTUATOR ......... OK")
print("TARGET ........... OK")
print("FLIGHT ........... OK")
print("DISPLAY .......... OK")


if telemetry then

    print(
        "TELEMETRY ........ OK"
    )

else

    print(
        "TELEMETRY ........ DISABLED"
    )

end


print("")
print("Starting systems...")
print("")


--------------------------------------------------
-- NAVIGATION PROCESS
--------------------------------------------------

local function navigationProcess()

    local success,
    err =
        pcall(
            navigation.run,
            state
        )


    if not success then

        state.system.error =
            "NAVIGATION: " ..
            tostring(
                err
            )


        state.system.status =
            "FAULT"


        state.system.running =
            false

    end

end


--------------------------------------------------
-- GUIDANCE PROCESS
--------------------------------------------------

local function guidanceProcess()

    local success,
    err =
        pcall(
            guidance.run,
            state
        )


    if not success then

        state.system.error =
            "GUIDANCE: " ..
            tostring(
                err
            )


        state.system.status =
            "FAULT"


        state.system.running =
            false

    end

end


--------------------------------------------------
-- ACTUATOR PROCESS
--------------------------------------------------

local function actuatorProcess()

    local success,
    err =
        pcall(
            actuator.run,
            state
        )


    if not success then

        state.system.error =
            "ACTUATOR: " ..
            tostring(
                err
            )


        state.system.status =
            "FAULT"


        state.system.running =
            false

    end

end


--------------------------------------------------
-- TARGET PROCESS
--------------------------------------------------

local function targetProcess()

    local success,
    err =
        pcall(
            target.run,
            state
        )


    if not success then

        state.system.error =
            "TARGET: " ..
            tostring(
                err
            )


        state.system.status =
            "FAULT"


        state.system.running =
            false

    end

end


--------------------------------------------------
-- FLIGHT PROCESS
--------------------------------------------------

local function flightProcess()

    local success,
    err =
        pcall(
            flight.run,
            state
        )


    if not success then

        state.system.error =
            "FLIGHT: " ..
            tostring(
                err
            )


        state.system.status =
            "FAULT"


        state.system.running =
            false

    end

end


--------------------------------------------------
-- DISPLAY PROCESS
--------------------------------------------------

local function displayProcess()

    local success,
    err =
        pcall(
            display.run,
            state
        )


    if not success then

        state.system.error =
            "DISPLAY: " ..
            tostring(
                err
            )


        state.system.status =
            "FAULT"


        state.system.running =
            false

    end

end


--------------------------------------------------
-- TELEMETRY PROCESS
--------------------------------------------------

local function telemetryProcess()

    if not telemetry then
        return
    end


    local success,
    err =
        pcall(
            telemetry.run,
            state
        )


    if not success then

        state.telemetry =
            state.telemetry
            or
            {}


        state.telemetry.online =
            false


        state.telemetry.status =
            "FAULT"


        state.telemetry.error =
            tostring(
                err
            )


        --------------------------------------------------
        -- Telemetry failure must NOT stop the missile
        -- control system.
        --------------------------------------------------

    end

end


--------------------------------------------------
-- ONLINE
--------------------------------------------------

state.system.status =
    "ONLINE"


--------------------------------------------------
-- START ALL SYSTEMS
--------------------------------------------------

if telemetry then

    parallel.waitForAll(

        navigationProcess,

        guidanceProcess,

        actuatorProcess,

        targetProcess,

        flightProcess,

        displayProcess,

        telemetryProcess

    )

else

    parallel.waitForAll(

        navigationProcess,

        guidanceProcess,

        actuatorProcess,

        targetProcess,

        flightProcess,

        displayProcess

    )

end


--------------------------------------------------
-- SHUTDOWN
--------------------------------------------------

state.system.running =
    false


state.system.controlEnabled =
    false


if state.system.status ~=
    "FAULT" then

    state.system.status =
        "STOPPED"

end


--------------------------------------------------
-- EXIT SCREEN
--------------------------------------------------

term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "================================"
)

print(
    "       MISSILE CONTROL"
)

print(
    "================================"
)

print("")


if state.system.error then

    print(
        "SYSTEM FAULT"
    )

    print("")


    print(
        state.system.error
    )

else

    print(
        "SYSTEM STOPPED"
    )

end


print("")


if state.telemetry then

    print(
        "TELEMETRY: " ..
        tostring(
            state.telemetry.status
            or
            "UNKNOWN"
        )
    )

end


print("")
print("Press any key...")


os.pullEvent(
    "key"
)