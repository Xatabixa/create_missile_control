-- Missile system display
-- Arrow keys / number keys switch pages. Q shuts down the system.

local state = require("state")

local screen = nil
local width = 0
local height = 0
local page = 1

local function openScreen()
    screen = peripheral.find("monitor") or term.current()

    if type(screen.setTextScale) == "function" then
        pcall(screen.setTextScale, 0.5)
    end

    width, height = screen.getSize()
    screen.setBackgroundColor(colors.black)
    screen.setTextColor(colors.white)
end

local function clear()
    screen.setBackgroundColor(colors.black)
    screen.setTextColor(colors.white)
    screen.clear()
    screen.setCursorPos(1, 1)
end

local function writeLine(row, text)
    if row < 1 or row > height then return end

    local value = tostring(text or "")
    if #value > width then
        value = value:sub(1, width)
    end

    screen.setCursorPos(1, row)
    screen.clearLine()
    screen.write(value)
end

local function fmt(value, digits)
    value = tonumber(value)
    if not value then return "---" end
    return string.format("%." .. tostring(digits or 1) .. "f", value)
end

local function angleDeg(value)
    value = tonumber(value)
    if not value then return "---" end
    return fmt(math.deg(value), 1)
end

local function header(title)
    writeLine(1, "=== MISSILE CONTROL SYSTEM ===")
    writeLine(2, "MODE: " .. tostring(state.system.mode))
    writeLine(3, "[1] NAV  [2] GUID  [3] ENG  [4] SYS")
    writeLine(4, "--------------------------------")
    writeLine(5, title)
    writeLine(6, "--------------------------------")
end

local function drawNavigation()
    clear()
    header("NAVIGATION")

    local n = state.navigation
    writeLine(7, "STATUS: " .. tostring(n.status))
    writeLine(8, "POS X " .. fmt(n.position.x, 1) .. "  Y " .. fmt(n.position.y, 1))
    writeLine(9, "POS Z " .. fmt(n.position.z, 1) .. "  GPS " .. (n.gps and "ON" or "OFF"))
    writeLine(10, "ALT " .. fmt(n.altitude, 1) .. "  VS " .. fmt(n.verticalSpeed, 1))
    writeLine(11, "SPEED " .. fmt(n.speed, 2) .. " m/s  PRESS " .. fmt(n.airPressure, 3))
    writeLine(12, "HDG " .. angleDeg(n.heading) .. "  PITCH " .. angleDeg(n.pitch) .. "  ROLL " .. angleDeg(n.roll))
    writeLine(13, "VX " .. fmt(n.velocity.x, 2) .. "  VY " .. fmt(n.velocity.y, 2) .. "  VZ " .. fmt(n.velocity.z, 2))
    writeLine(14, "AX " .. fmt(n.accelerationX, 2) .. " AY " .. fmt(n.accelerationY, 2) .. " AZ " .. fmt(n.accelerationZ, 2))
    writeLine(15, "GX " .. fmt(n.gravityX, 2) .. " GY " .. fmt(n.gravityY, 2) .. " GZ " .. fmt(n.gravityZ, 2))
    writeLine(16, "RATES X " .. fmt(n.angularRateX, 2) .. " Y " .. fmt(n.angularRateY, 2) .. " Z " .. fmt(n.angularRateZ, 2))
    writeLine(17, "NAV TABLE: " .. (n.navigationTable and "ON" or "OFF") .. "  ALT: " .. (n.altitudeSensor and "ON" or "OFF"))
    writeLine(18, "GIMBAL: " .. (n.gimbalSensor and "ON" or "OFF") .. "  VEL: " .. ((n.velocitySensorX or n.velocitySensorY or n.velocitySensorZ) and "ON" or "OFF"))
    writeLine(19, "TARGET: " .. (n.hasNavTarget and "LOCKED" or "NO LOCK") .. "  DIST " .. fmt(n.distance, 1))
    writeLine(20, "BEARING " .. angleDeg(n.bearing) .. "  OFFSET " .. fmt(n.elevation, 1) .. "m")
    writeLine(21, "CLOSURE " .. fmt(n.closureRate, 2) .. " m/s")
end

local function drawGuidance()
    clear()
    header("GUIDANCE")

    local g = state.guidance
    local n = state.navigation

    writeLine(7, "STATUS: " .. tostring(g.status))
    writeLine(8, "ACTIVE: " .. (g.active and "YES" or "NO"))
    writeLine(9, "TARGET: " .. (n.hasNavTarget and "LOCKED" or "NO LOCK"))
    writeLine(10, "BEARING ERROR: " .. angleDeg(n.bearing) .. " deg")
    writeLine(11, "VERTICAL OFFSET: " .. fmt(n.elevation, 2) .. " m")
    writeLine(12, "RANGE: " .. fmt(n.distance, 1) .. " m")
    writeLine(13, "CLOSURE: " .. fmt(n.closureRate, 2) .. " m/s")
    writeLine(14, "PITCH CMD: " .. fmt(g.commandX, 3))
    writeLine(15, "YAW CMD:   " .. fmt(g.commandY, 3))
    writeLine(16, "YAW ERROR: " .. angleDeg(g.yawError) .. " deg")
    writeLine(17, "PITCH ERR: " .. angleDeg(g.pitchError) .. " deg")
    writeLine(19, "CONTROL: " .. (state.system.controlEnabled and "ENABLED" or "DISABLED"))
    writeLine(20, "[1] NAV  [2] GUIDANCE  [3] ENGINE  [4] SYSTEM")
end

local function drawEngine()
    clear()
    header("VECTOR THRUSTER")

    local t = state.thruster
    writeLine(7, "STATUS: " .. tostring(t.status))
    writeLine(8, "COMMAND X: " .. fmt(state.guidance.commandX, 3))
    writeLine(9, "COMMAND Y: " .. fmt(state.guidance.commandY, 3))
    writeLine(11, "TARGET VECTOR X: " .. fmt(t.targetVectorX, 3))
    writeLine(12, "TARGET VECTOR Y: " .. fmt(t.targetVectorY, 3))
    writeLine(14, "ACTUAL VECTOR X: " .. fmt(t.vectorX, 3))
    writeLine(15, "ACTUAL VECTOR Y: " .. fmt(t.vectorY, 3))
    writeLine(17, "POWER:  " .. fmt(t.power, 3))
    writeLine(18, "THRUST: " .. fmt(t.thrust, 3))
    writeLine(20, "THRUST CONTROL: " .. (state.system.controlEnabled and "ENABLED" or "LOCKED"))
end

local function drawSystem()
    clear()
    header("SYSTEM")

    writeLine(7, "SYSTEM:    " .. tostring(state.system.status))
    writeLine(8, "NAVIGATION " .. (state.navigation.online and "ONLINE" or "OFFLINE"))
    writeLine(9, "GUIDANCE   " .. (state.guidance.online and "ONLINE" or "OFFLINE"))
    writeLine(10, "THRUSTER   " .. (state.thruster.online and "ONLINE" or "OFFLINE"))
    writeLine(11, "DISPLAY    ONLINE")
    writeLine(13, "CONTROL: " .. (state.system.controlEnabled and "ENABLED" or "DISABLED"))
    writeLine(14, "GPS:      " .. (state.navigation.gps and "ONLINE" or "OFFLINE"))
    writeLine(15, "NAV TABLE:" .. (state.navigation.navigationTable and " ONLINE" or " OFFLINE"))
    writeLine(16, "ALT SENSOR:" .. (state.navigation.altitudeSensor and " ONLINE" or " OFFLINE"))
    writeLine(17, "GIMBAL:    " .. (state.navigation.gimbalSensor and "ONLINE" or "OFFLINE"))
    writeLine(18, "VEL X/Y/Z: " .. (state.navigation.velocitySensorX and "X" or "-") .. "/" .. (state.navigation.velocitySensorY and "Y" or "-") .. "/" .. (state.navigation.velocitySensorZ and "Z" or "-"))
    writeLine(20, "[1] NAV  [2] GUID  [3] ENG  [4] SYS")
    writeLine(21, "ARROWS = PAGE    Q = SHUTDOWN")

    if state.system.error then
        writeLine(height, "ERROR: " .. tostring(state.system.error))
    end
end

local function draw()
    state.display.page = page

    if page == 1 then
        drawNavigation()
    elseif page == 2 then
        drawGuidance()
    elseif page == 3 then
        drawEngine()
    else
        drawSystem()
    end
end

local function selectPage(newPage)
    if newPage < 1 then newPage = 1 end
    if newPage > 4 then newPage = 4 end
    page = newPage
    draw()
end

local function handleKey(key)
    if key == keys.left or key == keys.one then
        selectPage(1)
    elseif key == keys.up or key == keys.two then
        selectPage(2)
    elseif key == keys.right or key == keys.three then
        selectPage(3)
    elseif key == keys.down or key == keys.four then
        selectPage(4)
    elseif key == keys.q then
        state.system.status = "SHUTTING DOWN"
        state.system.running = false
    end
end

local function handleTouch(x, y)
    if y >= height - 2 then
        local slot = math.floor((x - 1) * 4 / math.max(width, 1)) + 1
        selectPage(slot)
    end
end

local function run()
    openScreen()
    state.display.online = true
    draw()

    local timer = os.startTimer(0.10)

    while state.system.running do
        local event, a, b, c = os.pullEventRaw()

        if event == "timer" and a == timer then
            draw()
            timer = os.startTimer(0.10)
        elseif event == "key" then
            handleKey(a)
        elseif event == "monitor_touch" then
            handleTouch(b, c)
        elseif event == "terminate" then
            state.system.status = "SHUTTING DOWN"
            state.system.running = false
        end
    end

    state.display.online = false
end

return {
    run = run
}
