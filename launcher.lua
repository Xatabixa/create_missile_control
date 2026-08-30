-- Missile Control System Launcher

local BASE = "/rocket/"

--------------------------------------------------
-- LOAD STATE
--------------------------------------------------

local state = dofile(BASE .. "state.lua")

state.system.running = true
state.system.mode = "DRY TEST"
state.system.status = "STARTING"

--------------------------------------------------
-- LOAD MODULES
--------------------------------------------------

local function load(name)

    local path = BASE .. name

    if not fs.exists(path) then
        error("FILE NOT FOUND: " .. path)
    end

    local program, err =
        loadfile(path)

    if not program then
        error(
            "LOAD ERROR: " ..
            path ..
            "\n" ..
            tostring(err)
        )
    end

    return program
end

local navigation = load("navigation.lua")
local guidance = load("guidance.lua")
local actuator = load("actuator.lua")
local display = load("display.lua")

--------------------------------------------------
-- RUN
--------------------------------------------------

state.system.status = "ONLINE"

local function run(name, program)

    local ok, err =
        pcall(program)

    if not ok then

        state.system.status = "ERROR"
        state.system.running = false

        term.clear()
        term.setCursorPos(1, 1)

        print("MODULE ERROR")
        print("============")
        print("")
        print(name)
        print("")
        print(tostring(err))
        print("")
        print("Press any key...")

        os.pullEvent("key")

    end

end

parallel.waitForAny(

    function()
        run("NAVIGATION", navigation)
    end,

    function()
        run("GUIDANCE", guidance)
    end,

    function()
        run("ACTUATOR", actuator)
    end,

    function()
        run("DISPLAY", display)
    end

)

state.system.running = false

if state.system.status ~= "ERROR" then
    state.system.status = "OFFLINE"
end
