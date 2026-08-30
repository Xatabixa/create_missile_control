-- Engine and vector thruster test
-- This script directly controls the liquid vector thruster.
-- Run it instead of launcher.lua.

local thruster = peripheral.find("liquid_vector_thruster")

if not thruster then
    term.clear()
    term.setCursorPos(1, 1)

    print("ENGINE TEST")
    print("")
    print("ERROR: liquid_vector_thruster not found")
    return
end

local x = 0
local y = 0
local throttle = 0

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function apply()
    x = clamp(x, -1, 1)
    y = clamp(y, -1, 1)
    throttle = clamp(throttle, 0, 1)

    local ok, err = pcall(function()
        thruster.setVector(x, y)
        thruster.setThrustNormalized(throttle)
    end)

    if not ok then
        term.setCursorPos(1, 20)
        print("ERROR: " .. tostring(err))
        return false
    end

    return true
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

    return string.format("% .3f", value)
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("        ENGINE TEST")
    print("================================")
    print("")

    print("COMMAND")
    print("Vector X : " .. fmt(x))
    print("Vector Y : " .. fmt(y))
    print("Throttle : " .. fmt(throttle))
    print("")

    local actualX = get(thruster.getVectorX)
    local actualY = get(thruster.getVectorY)

    local targetX = get(thruster.getTargetVectorX)
    local targetY = get(thruster.getTargetVectorY)

    local power = get(thruster.getPower)
    local thrust = get(thruster.getThrust)

    print("ACTUAL VECTOR")
    print("X: " .. fmt(actualX))
    print("Y: " .. fmt(actualY))
    print("")

    print("TARGET VECTOR")
    print("X: " .. fmt(targetX))
    print("Y: " .. fmt(targetY))
    print("")

    print("ENGINE")
    print("Power : " .. fmt(power))
    print("Thrust: " .. fmt(thrust))
    print("")

    print("--------------------------------")
    print("ENTER  Set vector + throttle")
    print("R      Reset")
    print("Q      Quit")
    print("--------------------------------")
end

local function input()
    term.setCursorPos(1, 17)
    term.clearLine()
    term.write("X Y THROTTLE > ")

    local text = read()

    local sx, sy, st = text:match(
        "^%s*([%+%-]?[%d%.]+)%s+([%+%-]?[%d%.]+)%s+([%+%-]?[%d%.]+)%s*$"
    )

    if not sx or not sy or not st then
        return false, "Format: X Y THROTTLE"
    end

    local nx = tonumber(sx)
    local ny = tonumber(sy)
    local nt = tonumber(st)

    if not nx or not ny or not nt then
        return false, "Invalid number"
    end

    if nx < -1 or nx > 1 then
        return false, "X must be between -1 and 1"
    end

    if ny < -1 or ny > 1 then
        return false, "Y must be between -1 and 1"
    end

    if nt < 0 or nt > 1 then
        return false, "Throttle must be between 0 and 1"
    end

    x = nx
    y = ny
    throttle = nt

    return apply()
end

-- SAFETY: start with engine OFF and vector neutral.
x = 0
y = 0
throttle = 0

apply()
draw()

while true do
    local event, key = os.pullEvent("key")

    if key == keys.q then
        break

    elseif key == keys.r then
        x = 0
        y = 0
        throttle = 0
        apply()

    elseif key == keys.enter then
        local ok, err = input()

        if not ok then
            term.setCursorPos(1, 18)
            print("ERROR: " .. tostring(err))
            sleep(1)
        end
    end

    draw()
end

-- SAFETY SHUTDOWN
pcall(function()
    thruster.setThrustNormalized(0)
    thruster.setVector(0, 0)
end)

term.clear()
term.setCursorPos(1, 1)

print("ENGINE TEST STOPPED")
print("")
print("Throttle: 0.000")
print("Vector:   0.000, 0.000")