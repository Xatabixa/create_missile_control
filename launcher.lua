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
-- ONLINE
--------------------------------------------------

state.system.status =
    "ONLINE"


--------------------------------------------------
-- START ALL SYSTEMS
--------------------------------------------------

parallel.waitForAll(

    navigationProcess,

    guidanceProcess,

    actuatorProcess,

    targetProcess,

    flightProcess,

    displayProcess

)


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


print("================================")
print("       MISSILE CONTROL")
print("================================")
print("")


if state.system.error then

    print("SYSTEM FAULT")
    print("")

    print(
        state.system.error
    )

else

    print("SYSTEM STOPPED")

end


print("")
print("Press any key...")


os.pullEvent(
    "key"
)