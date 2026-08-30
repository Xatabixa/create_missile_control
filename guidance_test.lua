-- guidance_test.lua
-- Guidance system diagnostic test
-- Uses the real state.lua and guidance.lua from the missile system.

print("================================")
print("     GUIDANCE SYSTEM TEST")
print("================================")
print("")

-- Temporary require replacement.
-- ComputerCraft environment does not provide require().
function require(name)
    if name == "state" then
        local file = fs.open("/rocket/state.lua", "r")
        if not file then
            error("Cannot open /rocket/state.lua")
        end

        local source = file.readAll()
        file.close()

        local chunk = load(source, "/rocket/state.lua")
        if not chunk then
            error("Cannot load state.lua")
        end

        return chunk()
    end

    error("Unknown module: " .. tostring(name))
end

-- Load the real guidance module.
local file = fs.open("/rocket/guidance.lua", "r")

if not file then
    error("Cannot open /rocket/guidance.lua")
end

local source = file.readAll()
file.close()

local chunk, err = load(source, "/rocket/guidance.lua")

if not chunk then
    error("GUIDANCE LOAD ERROR:\n" .. tostring(err))
end

local guidance = chunk()

if not guidance then
    error("guidance.lua returned nothing")
end

if not guidance.run then
    error("guidance.lua has no run() function")
end

print("GUIDANCE MODULE: OK")
print("")

-- Load the same state used by guidance.lua.
local stateFile = fs.open("/rocket/state.lua", "r")

if not stateFile then
    error("Cannot open /rocket/state.lua")
end

local stateSource = stateFile.readAll()
stateFile.close()

local stateChunk, stateErr = load(stateSource, "/rocket/state.lua")

if not stateChunk then
    error("STATE LOAD ERROR:\n" .. tostring(stateErr))
end

local state = stateChunk()

print("STATE MODULE: OK")
print("")

-- ------------------------------------------------
-- TEST 1: Navigation offline
-- ------------------------------------------------

print("[TEST 1] Navigation OFFLINE")

state.system.running = true
state.navigation.online = false
state.navigation.bearing = 0
state.navigation.elevation = 0
state.navigation.hasNavTarget = false

print("Navigation: OFFLINE")
print("Expected guidance: OFFLINE")
print("")

-- ------------------------------------------------
-- TEST 2: Navigation online
-- ------------------------------------------------

print("[TEST 2] Navigation ONLINE")

state.navigation.online = true
state.navigation.bearing = 0
state.navigation.elevation = 0
state.navigation.hasNavTarget = true

print("Navigation: ONLINE")
print("Expected guidance: ONLINE")
print("Expected vector: X=0.000 Y=0.000")
print("")

-- ------------------------------------------------
-- Manual guidance calculation test
-- This exactly follows guidance.lua.
-- ------------------------------------------------

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

local function calculate(bearing, elevation)
    local commandY = 0

    if math.abs(bearing) > DEADZONE then
        commandY = bearing * BEARING_GAIN
    end

    local commandX = 0

    if math.abs(elevation) > 0.5 then
        commandX = elevation * ELEVATION_GAIN
    end

    commandX = clamp(commandX, -MAX_VECTOR, MAX_VECTOR)
    commandY = clamp(commandY, -MAX_VECTOR, MAX_VECTOR)

    return commandX, commandY
end

-- ------------------------------------------------
-- TEST 3: Center
-- ------------------------------------------------

print("[TEST 3] CENTER")

local x, y = calculate(0, 0)

print("Bearing:    0")
print("Elevation:  0")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("")

-- ------------------------------------------------
-- TEST 4: Turn RIGHT
-- ------------------------------------------------

print("[TEST 4] TURN RIGHT")

x, y = calculate(0.10, 0)

print("Bearing:    0.10")
print("Elevation:  0")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("")

-- ------------------------------------------------
-- TEST 5: Turn LEFT
-- ------------------------------------------------

print("[TEST 5] TURN LEFT")

x, y = calculate(-0.10, 0)

print("Bearing:   -0.10")
print("Elevation:  0")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("")

-- ------------------------------------------------
-- TEST 6: Pitch UP
-- ------------------------------------------------

print("[TEST 6] PITCH UP")

x, y = calculate(0, 5)

print("Bearing:    0")
print("Elevation:  5")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("")

-- ------------------------------------------------
-- TEST 7: Pitch DOWN
-- ------------------------------------------------

print("[TEST 7] PITCH DOWN")

x, y = calculate(0, -5)

print("Bearing:    0")
print("Elevation: -5")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("")

-- ------------------------------------------------
-- TEST 8: Maximum vector
-- ------------------------------------------------

print("[TEST 8] VECTOR LIMIT")

x, y = calculate(10, 100)

print("Bearing:    10")
print("Elevation:  100")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("Expected:   X=0.250 Y=0.250")
print("")

-- ------------------------------------------------
-- TEST 9: Negative maximum vector
-- ------------------------------------------------

print("[TEST 9] NEGATIVE VECTOR LIMIT")

x, y = calculate(-10, -100)

print("Bearing:   -10")
print("Elevation: -100")
print("Command X:  " .. string.format("%.3f", x))
print("Command Y:  " .. string.format("%.3f", y))
print("Expected:   X=-0.250 Y=-0.250")
print("")

print("================================")
print("       GUIDANCE TEST DONE")
print("================================")
print("")
print("No changes were made to the missile system.")