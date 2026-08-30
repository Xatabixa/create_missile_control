-- Exact vector thruster test
-- Run this instead of launcher.lua

local thruster = peripheral.find("vector_thruster")
    or peripheral.find("liquid_vector_thruster")

if not thruster then
    term.clear()
    term.setCursorPos(1, 1)

    print("ENGINE TEST")
    print("")
    print("ERROR: vector thruster not found")
    return
end

local x = 0
local y = 0

local function clamp(value)
    return math.max(-1, math.min(1, value))
end

local function setVector()
    x = clamp(x)
    y = clamp(y)

    local ok, err = pcall(thruster.setVector, x, y)

    if not ok then
        return false, tostring(err)
    end

    return true
end

local function getValue(method)
    local ok, value = pcall(method)

    if ok and value ~= nil then
        return value
    end

    return nil
end

local function draw()
    term.clear()
    term.setCursorPos(1, 1)

    print("================================")
    print("       ENGINE VECTOR TEST")
    print("================================")
    print("")

    print("COMMAND VECTOR")
    print("X: " .. string.format("% .3f", x))
    print("Y: " .. string.format("% .3f", y))
    print("")

    local actualX = getValue(thruster.getVectorX)
    local actualY = getValue(thruster.getVectorY)

    local targetX = getValue(thruster.getTargetVectorX)
    local targetY = getValue(thruster.getTargetVectorY)

    print("ACTUAL VECTOR")
    print("X: " .. (actualX and string.format("% .3f", actualX) or "N/A"))
    print("Y: " .. (actualY and string.format("% .3f", actualY) or "N/A"))
    print("")

    print("TARGET VECTOR")
    print("X: " .. (targetX and string.format("% .3f", targetX) or "N/A"))
    print("Y: " .. (targetY and string.format("% .3f", targetY) or "N/A"))
    print("")

    local power = getValue(thruster.getPower)
    local thrust = getValue(thruster.getThrust)

    print("ENGINE")
    print("Power : " .. (power and string.format("%.3f", power) or "N/A"))
    print("Thrust: " .. (thrust and string.format("%.3f", thrust) or "N/A"))

    print("")
    print("--------------------------------")
    print("ENTER X/Y VECTOR")
    print("Example: 0.25 -0.10")
    print("")
    print("R = reset to 0,0")
    print("Q = quit")
    print("--------------------------------")
end

local function readVector()
    term.setCursorPos(1, 15)
    term.clearLine()
    term.write("X Y > ")

    local input = read()

    local inputX, inputY = input:match(
        "^%s*([%+%-]?[%d%.]+)%s+([%+%-]?[%d%.]+)%s*$"
    )

    if not inputX or not inputY then
        return false, "Invalid format"
    end

    local newX = tonumber(inputX)
    local newY = tonumber(inputY)

    if not newX or not newY then
        return false, "Invalid number"
    end

    if newX < -1 or newX > 1 or newY < -1 or newY > 1 then
        return false, "Values must be between -1 and 1"
    end

    x = newX
    y = newY

    return setVector()
end

-- Initial neutral position
setVector()

while true do
    draw()

    local event, key = os.pullEvent("key")

    if key == keys.q then
        break
    elseif key == keys.r then
        x = 0
        y = 0
        setVector()
    elseif key == keys.enter then
        local ok, err = readVector()

        if not ok then
            term.setCursorPos(1, 17)
            print("ERROR: " .. err)
            sleep(1)
        end
    end
end

-- Always return the engine vector to neutral
pcall(thruster.setVector, 0, 0)

term.clear()
term.setCursorPos(1, 1)

print("ENGINE VECTOR TEST")
print("")
print("Vector returned to:")
print("X: 0.000")
print("Y: 0.000")