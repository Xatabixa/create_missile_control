-- Missile Control Display

local state = require("state")

local screen = nil
local width = 0
local height = 0

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
    screen.clear()
    screen.setCursorPos(1, 1)
end

local function line(row, text)
    if row < 1 or row > height then return end

    local output = tostring(text or "")
    if #output > width then output = output:sub(1, width) end

    screen.setCursorPos(1, row)
    screen.clearLine()
    screen.write(output)
end

local function fmt(value, digits)
    value = tonumber(value)
    if not value then return "---" end
    return string.format("%." .. tostring(digits or 1) .. "f", value)
end

local function boolText(value)
    return value and "ON" or "OFF"
end

local function draw()
    clear()

    line(1, "MISSILE CONTROL")
    line(2, "==============================")
    line(3, "SYSTEM: " .. tostring(state.system.status or "UNKNOWN"))
    line(4, "MODE:   " .. tostring(state.system.mode or "UNKNOWN"))
    line(5, "CONTROL: " .. boolText(state.system.controlEnabled))

    line(6, "")
    line(7, "NAVIGATION: " .. tostring(state.navigation.status or "OFFLINE"))
    line(8, "POS X: " .. fmt(state.navigation.position.x, 1))
    line(9, "POS Y: " .. fmt(state.navigation.position.y, 1))
    line(10, "POS Z: " .. fmt(state.navigation.position.z, 1))
    line(11, "ALT: " .. fmt(state.navigation.altitude, 1) .. "  V: " .. fmt(state.navigation.verticalSpeed, 1))
    line(12, "SPEED: " .. fmt(math.sqrt(
        (state.navigation.velocity.x or 0)^2 +
        (state.navigation.velocity.y or 0)^2 +
        (state.navigation.velocity.z or 0)^2
    ), 1) .. "  HDG: " .. fmt(math.deg(state.navigation.heading or 0), 1))

    line(13, "")
    line(14, "TARGET: " .. (state.navigation.hasNavTarget and "SET" or "NOT SET"))
    line(15, "DIST: " .. fmt(state.navigation.distance, 1) .. "  CLOSURE: " .. fmt(state.navigation.closureRate, 1))
    line(16, "BEARING: " .. fmt(math.deg(state.navigation.bearing or 0), 1) .. " deg")
    line(17, "ELEVATION: " .. fmt(math.deg(state.navigation.elevation or 0), 1) .. " deg")

    line(18, "GUIDANCE: " .. tostring(state.guidance.status or "OFFLINE"))
    line(19, "YAW: " .. fmt(math.deg(state.navigation.bearing or 0), 1) .. "  PITCH: " .. fmt(math.deg(state.navigation.elevation or 0), 1))
    line(20, "CMD X: " .. fmt(state.guidance.commandX, 2) .. "  Y: " .. fmt(state.guidance.commandY, 2))

    line(21, "ACTUATOR: " .. tostring(state.thruster.status or "OFFLINE"))
    line(22, "VECTOR X: " .. fmt(state.thruster.vectorX, 2) .. " Y: " .. fmt(state.thruster.vectorY, 2))
    line(23, "THRUST: " .. fmt(state.thruster.thrust, 2) .. " POWER: " .. fmt(state.thruster.power, 2))
    line(24, "Q = SHUTDOWN")

    if state.system.error then
        line(height, "ERROR: " .. tostring(state.system.error))
    end
end

local function init()
    openScreen()
    state.display.online = true
    draw()
end

local function run()
    init()

    local timer = os.startTimer(0.10)

    while state.system.running do
        local event, a, b, c = os.pullEventRaw()

        if event == "timer" and a == timer then
            draw()
            timer = os.startTimer(0.10)
        elseif event == "key" and a == keys.q then
            state.system.status = "SHUTTING DOWN"
            state.system.running = false
        elseif event == "monitor_touch" and c >= height - 1 then
            state.system.status = "SHUTTING DOWN"
            state.system.running = false
        elseif event == "terminate" then
            state.system.status = "SHUTTING DOWN"
            state.system.running = false
        end
    end

    draw()
    state.display.online = false
end

return {
    init = init,
    run = run
}
