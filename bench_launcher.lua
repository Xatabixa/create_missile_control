-- Missile Control Bench Launcher
-- CC:Tweaked
--
-- BENCH / TEST MODE
--
-- Loads:
--   state.lua
--   navigation.lua
--   target.lua
--   display.lua
--
-- DOES NOT LOAD:
--   guidance.lua
--   actuator.lua
--   flight.lua
--
-- Therefore this computer NEVER sends commands
-- to the vector thrusters.
--
-- Intended for:
--   - frozen rocket tests
--   - orientation tests
--   - gimbal tests
--   - navigation tests
--   - simultaneous thruster testing from another computer
--
-- Main control computer must NOT be running at
-- the same time if it would control the thrusters.

--------------------------------------------------
-- START SCREEN
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("     MISSILE CONTROL BENCH")
print("================================")
print("")
print("Loading bench system...")
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
-- LOAD BENCH MODULES
--------------------------------------------------

local navigation =
    loadModule(
        "navigation.lua"
    )


local target =
    loadModule(
        "target.lua"
    )


local display =
    loadModule(
        "display.lua"
    )


--------------------------------------------------
-- INITIAL STATE
--------------------------------------------------

state.system.running =
    true


state.system.mode =
    "BENCH TEST"


state.system.status =
    "BENCH ONLINE"


state.system.controlEnabled =
    false


state.system.error =
    nil


--------------------------------------------------
-- IMPORTANT
--
-- Guidance is intentionally not started.
-- Actuator is intentionally not started.
-- Flight is intentionally not started.
--
-- The state table may still contain their default
-- structures from state.lua; they simply have no
-- active process.
--------------------------------------------------

print("STATE ............ OK")
print("NAVIGATION ....... OK")
print("TARGET ........... OK")
print("DISPLAY .......... OK")
print("")
print("GUIDANCE ......... DISABLED")
print("ACTUATOR ......... DISABLED")
print("FLIGHT ........... DISABLED")
print("")
print("Starting bench...")
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
-- STATUS
--------------------------------------------------

state.system.status =
    "BENCH ONLINE"


--------------------------------------------------
-- START BENCH
--------------------------------------------------

parallel.waitForAll(

    navigationProcess,

    targetProcess,

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
        "BENCH STOPPED"

end


--------------------------------------------------
-- EXIT
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("================================")
print("     MISSILE CONTROL BENCH")
print("================================")
print("")

if state.system.error then

    print("BENCH FAULT")
    print("")

    print(
        state.system.error
    )

else

    print("BENCH STOPPED")

end

print("")
print("No actuator was loaded.")
print("Thruster control was disabled.")
print("")
print("Press any key...")


os.pullEvent(
    "key"
)