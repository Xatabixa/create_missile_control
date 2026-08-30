-- Guidance and vector actuator test
-- Does not modify the main missile control files.
-- Engine thrust is NOT controlled.

local state = dofile("state.lua")

local thruster = peripheral.find("vector_thruster")
    or peripheral.find("liquid_vector_thruster")

if not thruster then
    term.clear()
    term.setCursorPos(1, 1)

    print("GUIDANCE TEST")
    print("")
    print("ERROR: vector thruster not found")
    return
end

local MAX_VECTOR = 0.25
local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 0.05
local DEADZONE = math.rad(0.5)

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end

local function calculateGuidance()
    local bearing = state.navigation.bearing or 0
    local elevation = state.navigation.elevation or 0

    local commandY = 0
    local commandX = 0

    if math.abs(bearing) > DEADZONE then
        commandY = bearing * BEARING_GAIN
    end

    if math.abs(elevation) > 0.5 then
        commandX = elevation * ELEVATION_GAIN
    end

    commandX = clamp(commandX, -MAX_VECTOR, MAX_VECTOR)
    commandY = clamp(commandY, -MAX_VECTOR, MAX_VECTOR)

    state.guidance.commandX = commandX
    state.guidance.commandY = commandY
    state.guidance.yawError = bearing
    state.guidance.pitchError = elevation

    return commandX, commandY
end

local function applyVector()
    local x = state.guidance.commandX or 0
    local y = state.guidance.commandY or 0

    pcall(thruster.setVector, x, y)
end

local function get(method)
    local ok, value = pcall(method)

    if ok and value ~= nil then
        return value
    end

    return nil
end

local function fmt(value)
    if value == nil then
        return "N/A"
    end

    return string.format("% .4f", value)
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("        GUIDANCE TEST")
    print("================================")
    print("")

    print("INPUT")
    print("Bearing   : " .. fmt(state.navigation.bearing))
    print("Elevation : " .. fmt(state.navigation.elevation))
    print("Target    : " ..
        (state.navigation.hasNavTarget and "YES" or "NO"))
    print("")

    print("GUIDANCE COMMAND")
    print("Command X : " .. fmt(state.guidance.commandX))
    print("Command Y : " .. fmt(state.guidance.commandY))
    print("")

    print("THRUSTER")
    print("Actual X  : " .. fmt(get(thruster.getVectorX)))
    print("Actual Y  : " .. fmt(get(thruster.getVectorY)))
    print("Target X  : " .. fmt(get(thruster.getTargetVectorX)))
    print("Target Y  : " .. fmt(get(thruster.getTargetVectorY)))
    print("")

    print("--------------------------------")
    print("ENTER - Set navigation values")
    print("R     - Reset")
    print("Q     - Quit")
    print("--------------------------------")
end

local function readNumber(prompt)
    term.write(prompt)

    local value = tonumber(read())

    if value == nil then
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
    print("       NAVIGATION INPUT")
    print("================================")
    print("")

    print("Bearing: radians")
    print("Elevation: blocks")
    print("")

    local bearing = readNumber("Bearing: ")

    if bearing == nil then
        return
    end

    local elevation = readNumber("Elevation: ")

    if elevation == nil then
        return
    end

    local target = readNumber("Target (1/0): ")

    if target == nil then
        return
    end

    state.navigation.bearing = bearing
    state.navigation.elevation = elevation
    state.navigation.hasNavTarget = target == 1

    calculateGuidance()
    applyVector()
end

-- Initial state
state.navigation.online = true
state.navigation.status = "ONLINE"
state.navigation.hasNavTarget = false

state.guidance.online = true
state.guidance.status = "ONLINE"

state.guidance.commandX = 0
state.guidance.commandY = 0

pcall(thruster.setVector, 0, 0)

while true do
    calculateGuidance()
    applyVector()
    draw()

    local event, key = os.pullEvent("key")

    if key == keys.q then
        break
    end

    if key == keys.r then
        state.navigation.bearing = 0
        state.navigation.elevation = 0
        state.navigation.hasNavTarget = false

        state.guidance.commandX = 0
        state.guidance.commandY = 0

        pcall(thruster.setVector, 0, 0)
    end

    if key == keys.enter then
        manualInput()
    end
end

-- Safety shutdown
pcall(thruster.setVector, 0, 0)

term.clear()
term.setCursorPos(1, 1)

print("GUIDANCE TEST STOPPED")
print("")
print("Vector returned to 0, 0")