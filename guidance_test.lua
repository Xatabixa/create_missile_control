-- Guidance system test
-- Tests the real guidance.lua and actuator.lua.
-- Engine thrust remains disabled.

local state = require("state")

-- Start the shared system state.
state.system.running = true
state.system.mode = "GUIDANCE TEST"

-- Navigation must appear online for guidance.lua to calculate commands.
state.navigation.online = true

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function fmt(value)
    if value == nil then
        return "N/A"
    end

    return string.format("% .3f", value)
end

local function setNavigation(bearing, elevation)
    state.navigation.bearing = bearing
    state.navigation.elevation = elevation
end

local function clearNavigation()
    state.navigation.bearing = 0
    state.navigation.elevation = 0
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("        GUIDANCE TEST")
    print("================================")
    print("")

    print("NAVIGATION INPUT")
    print("Bearing   : " .. fmt(state.navigation.bearing))
    print("Elevation : " .. fmt(state.navigation.elevation))
    print("")

    print("GUIDANCE COMMAND")
    print("Command X : " .. fmt(state.guidance.commandX))
    print("Command Y : " .. fmt(state.guidance.commandY))
    print("")

    print("LIMIT")
    print("Maximum   : +/-0.250")
    print("")

    print("STATUS")
    print("Navigation: " ..
        (state.navigation.online and "ONLINE" or "OFFLINE"))

    print("Guidance  : " ..
        (state.guidance.online and "ONLINE" or "OFFLINE"))

    print("Thruster  : " ..
        (state.thruster.online and "ONLINE" or "OFFLINE"))

    print("")
    print("--------------------------------")
    print("ENTER - Set bearing/elevation")
    print("R     - Reset")
    print("Q     - Quit")
    print("--------------------------------")
end

local function readNumber(prompt)
    term.setCursorPos(1, 17)
    term.clearLine()
    term.write(prompt)

    local input = read()
    local value = tonumber(input)

    if not value then
        return nil
    end

    return value
end

local function setInput()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("      SET NAVIGATION INPUT")
    print("================================")
    print("")
    print("Values are in radians.")
    print("")

    local bearing = readNumber("Bearing: ")

    if bearing == nil then
        print("")
        print("Invalid bearing.")
        sleep(1)
        return
    end

    local elevation = readNumber("Elevation: ")

    if elevation == nil then
        print("")
        print("Invalid elevation.")
        sleep(1)
        return
    end

    setNavigation(bearing, elevation)

    print("")
    print("Input applied.")
    sleep(0.5)
end

local function runTestSequence()
    local tests = {
        {
            name = "NEUTRAL",
            bearing = 0,
            elevation = 0
        },
        {
            name = "RIGHT",
            bearing = math.rad(10),
            elevation = 0
        },
        {
            name = "LEFT",
            bearing = math.rad(-10),
            elevation = 0
        },
        {
            name = "FORWARD",
            bearing = 0,
            elevation = math.rad(10)
        },
        {
            name = "BACKWARD",
            bearing = 0,
            elevation = math.rad(-10)
        },
        {
            name = "RIGHT + FORWARD",
            bearing = math.rad(10),
            elevation = math.rad(10)
        }
    }

    for _, test in ipairs(tests) do
        setNavigation(test.bearing, test.elevation)

        term.clear()
        term.setCursorPos(1, 1)

        print("================================")
        print("      AUTOMATIC GUIDANCE TEST")
        print("================================")
        print("")
        print("TEST: " .. test.name)
        print("")
        print("Bearing   : " .. fmt(test.bearing))
        print("Elevation : " .. fmt(test.elevation))
        print("")
        print("Waiting for guidance...")
        sleep(0.2)

        print("")
        print("Command X : " .. fmt(state.guidance.commandX))
        print("Command Y : " .. fmt(state.guidance.commandY))

        sleep(1)
    end

    setNavigation(0, 0)

    print("")
    print("Test sequence completed.")
    sleep(1)
end

-- Load the real guidance and actuator modules.
parallel.waitForAll(
    function()
        guidance = loadfile("guidance.lua")

        if not guidance then
            error("Cannot load guidance.lua")
        end

        guidance()
    end,

    function()
        actuator = loadfile("actuator.lua")

        if not actuator then
            error("Cannot load actuator.lua")
        end

        actuator()
    end,

    function()
        -- Give both modules time to initialize.
        sleep(0.2)

        runTestSequence()

        while state.system.running do
            draw()

            local event, key = os.pullEvent("key")

            if key == keys.q then
                state.system.running = false
                break
            end

            if key == keys.r then
                clearNavigation()
                state.guidance.commandX = 0
                state.guidance.commandY = 0
            end

            if key == keys.enter then
                setInput()
            end
        end
    end
)

-- Safety reset.
state.system.running = false
state.navigation.online = false

state.guidance.commandX = 0
state.guidance.commandY = 0

clearNavigation()

term.clear()
term.setCursorPos(1, 1)

print("GUIDANCE TEST STOPPED")
print("")
print("Command X: 0.000")
print("Command Y: 0.000")