-- Guidance system test
-- Tests the real guidance and actuator modules.
-- Engine thrust is NOT controlled by this test.

local state = require("state")
local guidance = require("guidance")
local actuator = require("actuator")

state.system.running = true
state.system.mode = "GUIDANCE TEST"
state.system.status = "ONLINE"

-- Enable navigation input manually.
state.navigation.online = true
state.navigation.status = "ONLINE"

local function fmt(value)
    if value == nil then
        return "N/A"
    end

    return string.format("% .4f", value)
end

local function setInput(bearing, elevation, target)
    state.navigation.bearing = bearing
    state.navigation.elevation = elevation
    state.navigation.hasNavTarget = target
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
    print("Target    : " ..
        (state.navigation.hasNavTarget and "YES" or "NO"))
    print("")

    print("GUIDANCE")
    print("Status    : " .. tostring(state.guidance.status))
    print("Active    : " ..
        (state.guidance.active and "YES" or "NO"))
    print("Command X : " .. fmt(state.guidance.commandX))
    print("Command Y : " .. fmt(state.guidance.commandY))
    print("")

    print("THRUSTER")
    print("Status    : " .. tostring(state.thruster.status))
    print("Vector X  : " .. fmt(state.thruster.vectorX))
    print("Vector Y  : " .. fmt(state.thruster.vectorY))
    print("Target X  : " .. fmt(state.thruster.targetVectorX))
    print("Target Y  : " .. fmt(state.thruster.targetVectorY))
    print("")

    print("--------------------------------")
    print("ENTER - Manual input")
    print("R     - Reset")
    print("Q     - Quit")
    print("--------------------------------")
end

local function readNumber(prompt)
    term.write(prompt)

    local input = read()
    local value = tonumber(input)

    if not value then
        print("Invalid number.")
        sleep(1)
        return nil
    end

    return value
end

local function manualInput()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("       MANUAL GUIDANCE TEST")
    print("================================")
    print("")

    print("Bearing is an angle in radians.")
    print("Elevation is a signed vertical offset.")
    print("")

    local bearing = readNumber("Bearing: ")

    if bearing == nil then
        return
    end

    local elevation = readNumber("Elevation: ")

    if elevation == nil then
        return
    end

    local target = readNumber("Target (1=yes, 0=no): ")

    if target == nil then
        return
    end

    setInput(
        bearing,
        elevation,
        target == 1
    )

    sleep(0.2)
end

local function guidanceTask()
    local ok, err = pcall(guidance.run)

    if not ok then
        state.system.error = "GUIDANCE: " .. tostring(err)
        state.system.running = false
    end
end

local function actuatorTask()
    local ok, err = pcall(actuator.run)

    if not ok then
        state.system.error = "ACTUATOR: " .. tostring(err)
        state.system.running = false
    end
end

parallel.waitForAny(
    guidanceTask,
    actuatorTask,
    function()
        while state.system.running do
            draw()

            local event, key = os.pullEvent("key")

            if key == keys.q then
                state.system.running = false
                break
            end

            if key == keys.r then
                setInput(0, 0, false)
            end

            if key == keys.enter then
                manualInput()
            end
        end
    end
)

-- Safety shutdown.
state.system.running = false

state.navigation.online = false
state.navigation.hasNavTarget = false

state.guidance.commandX = 0
state.guidance.commandY = 0

term.clear()
term.setCursorPos(1, 1)

print("GUIDANCE TEST STOPPED")
print("")
print("Vector command reset to:")
print("X: 0.0000")
print("Y: 0.0000")