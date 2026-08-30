-- Engine and vector thruster test
-- Exact vector and throttle control.

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

    return ok, err
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
    print("          ENGINE TEST")
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
    print("ENTER - Set vector/throttle")
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

local function inputValues()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("       SET ENGINE VALUES")
    print("================================")
    print("")
    print("Enter values one by one.")
    print("")

    local newX = readNumber("Vector X (-1 to 1): ")

    if newX == nil then
        print("")
        print("Invalid X value.")
        sleep(1)
        return
    end

    if newX < -1 or newX > 1 then
        print("")
        print("X must be between -1 and 1.")
        sleep(1)
        return
    end

    local newY = readNumber("Vector Y (-1 to 1): ")

    if newY == nil then
        print("")
        print("Invalid Y value.")
        sleep(1)
        return
    end

    if newY < -1 or newY > 1 then
        print("")
        print("Y must be between -1 and 1.")
        sleep(1)
        return
    end

    local newThrottle = readNumber("Throttle (0 to 1): ")

    if newThrottle == nil then
        print("")
        print("Invalid throttle value.")
        sleep(1)
        return
    end

    if newThrottle < 0 or newThrottle > 1 then
        print("")
        print("Throttle must be between 0 and 1.")
        sleep(1)
        return
    end

    x = newX
    y = newY
    throttle = newThrottle

    local ok, err = apply()

    if not ok then
        print("")
        print("ERROR:")
        print(tostring(err))
        sleep(2)
    end
end

-- Safety startup state.
apply()

while true do
    draw()

    local event, key = os.pullEvent("key")

    if key == keys.q then
        break
    end

    if key == keys.r then
        x = 0
        y = 0
        throttle = 0
        apply()
    end

    if key == keys.enter then
        inputValues()
    end
end

-- Safety shutdown.
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