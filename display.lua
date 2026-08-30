-- Missile control display
-- 1/2/3/4 = pages
-- I = target coordinates
-- C = enable/disable automatic control
-- Q = shutdown

local screen
local width = 0
local height = 0

local page = 1

local function openScreen()
    screen =
        peripheral.find("monitor")
        or term.current()

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
    if row < 1 or row > height then
        return
    end

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

    if not value then
        return "---"
    end

    return string.format(
        "%." .. tostring(digits or 1) .. "f",
        value
    )
end

local function angleDeg(value)
    value = tonumber(value)

    if not value then
        return "---"
    end

    return fmt(math.deg(value), 1)
end

local function header(state, title)
    writeLine(
        1,
        "=== MISSILE CONTROL SYSTEM ==="
    )

    writeLine(
        2,
        "MODE: " .. tostring(state.system.mode)
    )

    writeLine(
        3,
        "[1]NAV [2]GUID [3]ENG [4]SYS [I]TARGET"
    )

    writeLine(
        4,
        "--------------------------------"
    )

    writeLine(5, title)
    writeLine(
        6,
        "--------------------------------"
    )
end

local function drawNavigation(state)
    clear()
    header(state, "NAVIGATION")

    local n = state.navigation

    writeLine(
        7,
        "STATUS: " .. tostring(n.status)
    )

    writeLine(
        8,
        "POS X " .. fmt(n.position.x, 1)
        .. " Y " .. fmt(n.position.y, 1)
    )

    writeLine(
        9,
        "POS Z " .. fmt(n.position.z, 1)
        .. " GPS "
        .. (n.gps and "ON" or "OFF")
    )

    writeLine(
        10,
        "ALT " .. fmt(n.altitude, 1)
        .. " VS "
        .. fmt(n.verticalSpeed, 1)
    )

    writeLine(
        11,
        "SPEED "
        .. fmt(n.speed, 2)
        .. " m/s"
    )

    writeLine(
        12,
        "HDG "
        .. angleDeg(n.heading)
        .. " PITCH "
        .. angleDeg(n.pitch)
        .. " ROLL "
        .. angleDeg(n.roll)
    )

    writeLine(
        13,
        "VX "
        .. fmt(n.velocity.x, 2)
        .. " VY "
        .. fmt(n.velocity.y, 2)
        .. " VZ "
        .. fmt(n.velocity.z, 2)
    )

    writeLine(
        14,
        "NAV TABLE: "
        .. (n.navigationTable and "ON" or "OFF")
    )

    writeLine(
        15,
        "ALT SENSOR: "
        .. (n.altitudeSensor and "ON" or "OFF")
    )

    writeLine(
        16,
        "GIMBAL: "
        .. (n.gimbalSensor and "ON" or "OFF")
    )

    writeLine(
        17,
        "VEL: "
        .. (n.velocitySensorX and "X" or "-")
        .. "/"
        .. (n.velocitySensorY and "Y" or "-")
        .. "/"
        .. (n.velocitySensorZ and "Z" or "-")
    )

    writeLine(
        18,
        "TARGET: "
        .. (n.hasNavTarget and "LOCKED" or "NO LOCK")
    )

    writeLine(
        19,
        "DIST: "
        .. fmt(n.distance, 1)
        .. " m"
    )

    writeLine(
        20,
        "BEARING: "
        .. angleDeg(n.bearing)
        .. " deg"
    )

    writeLine(
        21,
        "VERT OFFSET: "
        .. fmt(n.elevation, 2)
        .. " m"
    )
end

local function drawGuidance(state)
    clear()
    header(state, "GUIDANCE")

    local g = state.guidance
    local n = state.navigation

    writeLine(
        7,
        "STATUS: " .. tostring(g.status)
    )

    writeLine(
        8,
        "ACTIVE: "
        .. (g.active and "YES" or "NO")
    )

    writeLine(
        9,
        "TARGET: "
        .. (n.hasNavTarget and "LOCKED" or "NO LOCK")
    )

    writeLine(
        10,
        "YAW ERROR: "
        .. angleDeg(g.yawError)
        .. " deg"
    )

    writeLine(
        11,
        "PITCH ERROR: "
        .. fmt(g.pitchError, 2)
        .. " m"
    )

    writeLine(
        13,
        "COMMAND X: "
        .. fmt(g.commandX, 3)
    )

    writeLine(
        14,
        "COMMAND Y: "
        .. fmt(g.commandY, 3)
    )

    writeLine(
        16,
        "CONTROL: "
        .. (
            state.system.controlEnabled
            and "ENABLED"
            or "DISABLED"
        )
    )

    writeLine(
        18,
        "TARGET BEARING: "
        .. angleDeg(g.targetBearing)
    )

    writeLine(
        19,
        "TARGET ELEVATION: "
        .. fmt(g.targetElevation, 2)
    )
end

local function drawEngine(state)
    clear()
    header(state, "VECTOR THRUSTER")

    local t = state.thruster

    writeLine(
        7,
        "STATUS: " .. tostring(t.status)
    )

    writeLine(
        8,
        "AUTO X: "
        .. fmt(state.guidance.commandX, 3)
    )

    writeLine(
        9,
        "AUTO Y: "
        .. fmt(state.guidance.commandY, 3)
    )

    writeLine(
        11,
        "TARGET X: "
        .. fmt(t.targetVectorX, 3)
    )

    writeLine(
        12,
        "TARGET Y: "
        .. fmt(t.targetVectorY, 3)
    )

    writeLine(
        14,
        "ACTUAL X: "
        .. fmt(t.vectorX, 3)
    )

    writeLine(
        15,
        "ACTUAL Y: "
        .. fmt(t.vectorY, 3)
    )

    writeLine(
        17,
        "POWER: "
        .. fmt(t.power, 3)
    )

    writeLine(
        18,
        "THRUST: "
        .. fmt(t.thrust, 3)
    )

    writeLine(
        20,
        "CONTROL: "
        .. (
            state.system.controlEnabled
            and "ENABLED"
            or "LOCKED"
        )
    )
end

local function drawSystem(state)
    clear()
    header(state, "SYSTEM")

    writeLine(
        7,
        "SYSTEM: "
        .. tostring(state.system.status)
    )

    writeLine(
        8,
        "NAVIGATION "
        .. (state.navigation.online
            and "ONLINE"
            or "OFFLINE")
    )

    writeLine(
        9,
        "GUIDANCE "
        .. (state.guidance.online
            and "ONLINE"
            or "OFFLINE")
    )

    writeLine(
        10,
        "THRUSTER "
        .. (state.thruster.online
            and "ONLINE"
            or "OFFLINE")
    )

    writeLine(
        11,
        "DISPLAY ONLINE"
    )

    writeLine(
        13,
        "CONTROL: "
        .. (
            state.system.controlEnabled
            and "ENABLED"
            or "DISABLED"
        )
    )

    writeLine(
        14,
        "TARGET: "
        .. (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

    writeLine(
        15,
        "X "
        .. fmt(state.target.x, 1)
        .. " Y "
        .. fmt(state.target.y, 1)
    )

    writeLine(
        16,
        "Z "
        .. fmt(state.target.z, 1)
    )

    writeLine(
        18,
        "GPS "
        .. (
            state.navigation.gps
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        19,
        "NAV TABLE "
        .. (
            state.navigation.navigationTable
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        20,
        "ALT SENSOR "
        .. (
            state.navigation.altitudeSensor
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        21,
        "GIMBAL "
        .. (
            state.navigation.gimbalSensor
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        23,
        "C = AUTO CONTROL"
    )

    writeLine(
        24,
        "I = SET TARGET"
    )

    writeLine(
        25,
        "Q = SHUTDOWN"
    )

    if state.system.error then
        writeLine(
            height,
            "ERROR: "
            .. tostring(state.system.error)
        )
    end
end

local function draw(state)
    state.display.page = page

    if page == 1 then
        drawNavigation(state)
    elseif page == 2 then
        drawGuidance(state)
    elseif page == 3 then
        drawEngine(state)
    else
        drawSystem(state)
    end
end

local function saveTarget(state, x, y, z)
    local data = {
        x = x,
        y = y,
        z = z,
        set = true,
        revision =
            (tonumber(state.target.revision) or 0) + 1
    }

    local file = fs.open("target.cfg", "w")

    if not file then
        return false, "Cannot write target.cfg"
    end

    file.write(textutils.serialize(data))
    file.close()

    state.target.x = x
    state.target.y = y
    state.target.z = z
    state.target.set = true
    state.target.revision = data.revision

    return true
end

local function loadTarget(state)
    if not fs.exists("target.cfg") then
        return
    end

    local file = fs.open("target.cfg", "r")

    if not file then
        return
    end

    local content = file.readAll()
    file.close()

    local data = textutils.unserialize(content)

    if type(data) ~= "table" then
        return
    end

    state.target.x = tonumber(data.x) or 0
    state.target.y = tonumber(data.y) or 0
    state.target.z = tonumber(data.z) or 0
    state.target.set = data.set == true
    state.target.revision =
        tonumber(data.revision) or 0
end

local function targetInput(state)
    local values = {"", "", ""}
    local active = 1

    while true do
        clear()

        writeLine(
            1,
            "=== MISSILE CONTROL SYSTEM ==="
        )

        writeLine(
            2,
            "TARGET COORDINATE INPUT"
        )

        writeLine(4, "ENTER TARGET COORDINATES")

        writeLine(
            7,
            (active == 1 and "> " or "  ")
            .. "X: "
            .. values[1]
        )

        writeLine(
            8,
            (active == 2 and "> " or "  ")
            .. "Y: "
            .. values[2]
        )

        writeLine(
            9,
            (active == 3 and "> " or "  ")
            .. "Z: "
            .. values[3]
        )

        writeLine(
            11,
            "ENTER = NEXT / SAVE"
        )

        writeLine(
            12,
            "BACKSPACE = DELETE"
        )

        writeLine(
            13,
            "ESC = CANCEL"
        )

        local event, a =
            os.pullEventRaw()

        if event == "char" then
            if type(a) == "string"
                and #a == 1
                and a:match("[%d%.%-]") then

                values[active] =
                    values[active] .. a
            end

        elseif event == "key" then

            if a == keys.backspace then
                values[active] =
                    values[active]:sub(1, -2)

            elseif a == keys.enter then

                if values[active] == ""
                    or tonumber(values[active]) == nil then

                    writeLine(
                        15,
                        "INVALID COORDINATE"
                    )

                    sleep(0.8)

                elseif active < 3 then
                    active = active + 1

                else
                    local x = tonumber(values[1])
                    local y = tonumber(values[2])
                    local z = tonumber(values[3])

                    local ok, err =
                        saveTarget(
                            state,
                            x,
                            y,
                            z
                        )

                    if not ok then
                        writeLine(
                            15,
                            tostring(err)
                        )

                        sleep(1)
                    else
                        draw(state)
                        return
                    end
                end

            elseif a == keys.escape then
                draw(state)
                return
            end

        elseif event == "terminate" then
            state.system.running = false
            return
        end
    end
end

local function handleKey(state, key)
    if key == keys.one then
        page = 1
        draw(state)

    elseif key == keys.two then
        page = 2
        draw(state)

    elseif key == keys.three then
        page = 3
        draw(state)

    elseif key == keys.four then
        page = 4
        draw(state)

    elseif key == keys.i then
        targetInput(state)

    elseif key == keys.c then
        state.system.controlEnabled =
            not state.system.controlEnabled

        if state.system.controlEnabled then
            state.system.status =
                "CONTROL ENABLED"
        else
            state.system.status =
                "CONTROL STANDBY"
        end

    elseif key == keys.q then
        state.system.status =
            "SHUTTING DOWN"

        state.system.running = false
    end
end

local function handleTouch(state, x, y)
    if y >= height - 3 then
        local slot =
            math.floor(
                (x - 1) * 4
                / math.max(width, 1)
            ) + 1

        if slot < 1 then
            slot = 1
        end

        if slot > 4 then
            slot = 4
        end

        page = slot
        draw(state)
    end
end

local function run(state)
    openScreen()

    loadTarget(state)

    state.display.online = true

    draw(state)

    local timer =
        os.startTimer(0.10)

    while state.system.running do

        local event, a, b, c =
            os.pullEventRaw()

        if event == "timer"
            and a == timer then

            draw(state)

            timer =
                os.startTimer(0.10)

        elseif event == "key" then
            handleKey(state, a)

        elseif event == "monitor_touch" then
            handleTouch(state, b, c)

        elseif event == "terminate" then
            state.system.running = false
        end
    end

    state.display.online = false
end

return {
    run = run
}