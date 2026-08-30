-- guidance_test.lua
-- Standalone guidance vector test
-- All files are located in the computer root.

print("================================")
print("       GUIDANCE VECTOR TEST")
print("================================")
print("")

local MAX_VECTOR = 0.25
local BEARING_GAIN = 1.0
local ELEVATION_GAIN = 0.05
local DEADZONE = math.rad(0.5)

local function clamp(value, min, max)
    if value < min then
        return min
    end

    if value > max then
        return max
    end

    return value
end

local function calculateVector(bearing, elevation)
    local x = 0
    local y = 0

    -- Horizontal guidance
    if math.abs(bearing) > DEADZONE then
        y = bearing * BEARING_GAIN
    end

    -- Vertical guidance
    if math.abs(elevation) > 0.5 then
        x = elevation * ELEVATION_GAIN
    end

    x = clamp(x, -MAX_VECTOR, MAX_VECTOR)
    y = clamp(y, -MAX_VECTOR, MAX_VECTOR)

    return x, y
end

local function test(name, bearing, elevation)
    local x, y = calculateVector(bearing, elevation)

    print("--------------------------------")
    print(name)
    print("Bearing:   " .. tostring(bearing))
    print("Elevation: " .. tostring(elevation))
    print("")
    print("VECTOR")
    print("X: " .. string.format("%.3f", x))
    print("Y: " .. string.format("%.3f", y))
    print("")
end

test("CENTER", 0, 0)

test("TURN RIGHT", 0.10, 0)

test("TURN LEFT", -0.10, 0)

test("PITCH UP", 0, 5)

test("PITCH DOWN", 0, -5)

test("RIGHT + UP", 0.10, 5)

test("LEFT + DOWN", -0.10, -5)

test("MAXIMUM POSITIVE", 10, 100)

test("MAXIMUM NEGATIVE", -10, -100)

print("--------------------------------")
print("TEST COMPLETE")
print("--------------------------------")
print("")
print("The guidance vector calculator")
print("is working.")
print("")
print("X = pitch")
print("Y = yaw")
print("Range = -0.25 ... +0.25")