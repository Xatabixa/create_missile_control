-- Missile Control System Display
-- ComputerCraft single-folder version
-- No require() is used.

local screen = nil
local width = 0
local height = 0
local page = 1

--------------------------------------------------
-- SCREEN
--------------------------------------------------

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

--------------------------------------------------
-- TARGET FILE
--------------------------------------------------

local TARGET_FILE = "target.cfg"

local function saveTarget(state)
    local file = fs.open(TARGET_FILE, "w")

    if not file then
        return false, "CANNOT OPEN TARGET FILE"
    end

    local data = {
        x = tonumber(state.target.x) or 0,
        y = tonumber(state.target.y) or 0,
        z = tonumber(state.target.z) or 0,
        set = state.target.set == true,
        revision = tonumber(state.target.revision) or 0
    }

    file.write(textutils.serialize(data))
    file.close()

    return true
end

local function loadTarget(state)
    if not fs.exists(TARGET_FILE) then
        return
    end

    local file = fs.open(TARGET_FILE, "r")

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
    state.target.revision = tonumber(data.revision) or 0
end

--------------------------------------------------
-- HEADER
--------------------------------------------------

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
        "[1] NAV [2] GUID [3] ENG [4] SYS [I] TARGET"
    )

    writeLine(
        4,
        "--------------------------------"
    )

    writeLine(
        5,
        title
    )

    writeLine(
        6,
        "--------------------------------"
    )
end

--------------------------------------------------
-- NAVIGATION
--------------------------------------------------

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
        "POS X " .. fmt(n.position.x, 1) ..
        " Y " .. fmt(n.position.y, 1)
    )

    writeLine(
        9,
        "POS Z " .. fmt(n.position.z, 1) ..
        " GPS " .. (n.gps and "ON" or "OFF")
    )

    writeLine(
        10,
        "ALT " .. fmt(n.altitude, 1) ..
        " VS " .. fmt(n.verticalSpeed, 1)
    )

    writeLine(
        11,
        "SPEED " .. fmt(n.speed, 2) ..
        " m/s PRESS " .. fmt(n.airPressure, 3)
    )

    writeLine(
        12,
        "HDG " .. angleDeg(n.heading) ..
        " PITCH " .. angleDeg(n.pitch) ..
        " ROLL " .. angleDeg(n.roll)
    )

    writeLine(
        13,
        "VX " .. fmt(n.velocity.x, 2) ..
        " VY " .. fmt(n.velocity.y, 2) ..
        " VZ " .. fmt(n.velocity.z, 2)
    )

    writeLine(
        14,
        "AX " .. fmt(n.accelerationX, 2) ..
        " AY " .. fmt(n.accelerationY, 2) ..
        " AZ " .. fmt(n.accelerationZ, 2)
    )

    writeLine(
        15,
        "GX " .. fmt(n.gravityX, 2) ..
        " GY " .. fmt(n.gravityY, 2) ..
        " GZ " .. fmt(n.gravityZ, 2)
    )

    writeLine(
        16,
        "RATES X " .. fmt(n.angularRateX, 2) ..
        " Y " .. fmt(n.angularRateY, 2) ..
        " Z " .. fmt(n.angularRateZ, 2)
    )

    writeLine(
        17,
        "NAV TABLE: " ..
        (n.navigationTable and "ON" or "OFF") ..
        " ALT: " ..
        (n.altitudeSensor and "ON" or "OFF")
    )

    writeLine(
        18,
        "GIMBAL: " ..
        (n.gimbalSensor and "ON" or "OFF") ..
        " VEL: " ..
        (
            (
                n.velocitySensorX or
                n.velocitySensorY or
                n.velocitySensorZ
            )
            and "ON"
            or "OFF"
        )
    )

    writeLine(
        19,
        "TARGET: " ..
        (n.hasNavTarget and "LOCKED" or "NO LOCK") ..
        " DIST " ..
        fmt(n.distance, 1)
    )

    writeLine(
        20,
        "BEARING " ..
        angleDeg(n.bearing) ..
        " OFFSET " ..
        fmt(n.elevation, 1) ..
        "m"
    )

    writeLine(
        21,
        "CLOSURE " ..
        fmt(n.closureRate, 2) ..
        " m/s"
    )
end

--------------------------------------------------
-- GUIDANCE
--------------------------------------------------

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
        "ACTIVE: " ..
        (g.active and "YES" or "NO")
    )

    writeLine(
        9,
        "TARGET: " ..
        (n.hasNavTarget and "LOCKED" or "NO LOCK")
    )

    writeLine(
        10,
        "BEARING ERROR: " ..
        angleDeg(n.bearing) ..
        " deg"
    )

    writeLine(
        11,
        "VERTICAL OFFSET: " ..
        fmt(n.elevation, 2) ..
        " m"
    )

    writeLine(
        12,
        "RANGE: " ..
        fmt(n.distance, 1) ..
        " m"
    )

    writeLine(
        13,
        "CLOSURE: " ..
        fmt(n.closureRate, 2) ..
        " m/s"
    )

    writeLine(
        14,
        "PITCH CMD: " ..
        fmt(g.commandX, 3)
    )

    writeLine(
        15,
        "YAW CMD: " ..
        fmt(g.commandY, 3)
    )

    writeLine(
        16,
        "YAW ERROR: " ..
        angleDeg(g.yawError) ..
        " deg"
    )

    writeLine(
        17,
        "PITCH ERR: " ..
        angleDeg(g.pitchError) ..
        " deg"
    )

    writeLine(
        19,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ENABLED"
            or "DISABLED"
        )
    )

    writeLine(
        20,
        "[C] CONTROL ON/OFF"
    )
end

--------------------------------------------------
-- ENGINE
--------------------------------------------------

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
        "COMMAND X: " ..
        fmt(state.guidance.commandX, 3)
    )

    writeLine(
        9,
        "COMMAND Y: " ..
        fmt(state.guidance.commandY, 3)
    )

    writeLine(
        11,
        "TARGET VECTOR X: " ..
        fmt(t.targetVectorX, 3)
    )

    writeLine(
        12,
        "TARGET VECTOR Y: " ..
        fmt(t.targetVectorY, 3)
    )

    writeLine(
        14,
        "ACTUAL VECTOR X: " ..
        fmt(t.vectorX, 3)
    )

    writeLine(
        15,
        "ACTUAL VECTOR Y: " ..
        fmt(t.vectorY, 3)
    )

    writeLine(
        17,
        "POWER: " ..
        fmt(t.power, 3)
    )

    writeLine(
        18,
        "THRUST: " ..
        fmt(t.thrust, 3)
    )

    writeLine(
        20,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ENABLED"
            or "LOCKED"
        )
    )

    writeLine(
        21,
        "[C] CONTROL ON/OFF"
    )
end

--------------------------------------------------
-- SYSTEM
--------------------------------------------------

local function drawSystem(state)
    clear()

    header(state, "SYSTEM")

    writeLine(
        7,
        "SYSTEM: " ..
        tostring(state.system.status)
    )

    writeLine(
        8,
        "NAVIGATION " ..
        (
            state.navigation.online
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        9,
        "GUIDANCE " ..
        (
            state.guidance.online
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        10,
        "THRUSTER " ..
        (
            state.thruster.online
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        11,
        "DISPLAY ONLINE"
    )

    writeLine(
        13,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ENABLED"
            or "DISABLED"
        )
    )

    writeLine(
        14,
        "TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

    writeLine(
        15,
        "X: " ..
        fmt(state.target.x, 1) ..
        " Y: " ..
        fmt(state.target.y, 1)
    )

    writeLine(
        16,
        "Z: " ..
        fmt(state.target.z, 1) ..
        " REV: " ..
        tostring(state.target.revision or 0)
    )

    writeLine(
        18,
        "GPS: " ..
        (
            state.navigation.gps
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        19,
        "NAV TABLE:" ..
        (
            state.navigation.navigationTable
            and " ONLINE"
            or " OFFLINE"
        )
    )

    writeLine(
        20,
        "ALT SENSOR:" ..
        (
            state.navigation.altitudeSensor
            and " ONLINE"
            or " OFFLINE"
        )
    )

    writeLine(
        21,
        "GIMBAL:" ..
        (
            state.navigation.gimbalSensor
            and "ONLINE"
            or "OFFLINE"
        )
    )

    writeLine(
        22,
        "VEL X/Y/Z: " ..
        (
            state.navigation.velocitySensorX
            and "X"
            or "-"
        ) ..
        "/" ..
        (
            state.navigation.velocitySensorY
            and "Y"
            or "-"
        ) ..
        "/" ..
        (
            state.navigation.velocitySensorZ
            and "Z"
            or "-"
        )
    )

    writeLine(
        24,
        "[1] NAV [2] GUID [3] ENG [4] SYS"
    )

    writeLine(
        25,
        "I = TARGET   C = CONTROL   Q = STOP"
    )

    if state.system.error then
        writeLine(
            height,
            "ERROR: " ..
            tostring(state.system.error)
        )
    end
end

--------------------------------------------------
-- DRAW
--------------------------------------------------

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

--------------------------------------------------
-- TARGET INPUT SCREEN
--------------------------------------------------

local function drawTargetInput(values, active)
    clear()

    writeLine(
        1,
        "=== MISSILE CONTROL SYSTEM ==="
    )

    writeLine(
        2,
        "TARGET COORDINATE INPUT"
    )

    writeLine(
        3,
        "--------------------------------"
    )

    writeLine(
        5,
        "Enter target coordinates:"
    )

    writeLine(
        7,
        (
            active == 1 and "> " or "  "
        ) ..
        "X: " ..
        values[1]
    )

    writeLine(
        8,
        (
            active == 2 and "> " or "  "
        ) ..
        "Y: " ..
        values[2]
    )

    writeLine(
        9,
        (
            active == 3 and "> " or "  "
        ) ..
        "Z: " ..
        values[3]
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
        "R = CANCEL"
    )
end

--------------------------------------------------
-- TARGET INPUT
--------------------------------------------------

local function setTarget(state)
    local values = {
        "",
        "",
        ""
    }

    local active = 1

    drawTargetInput(values, active)

    while true do
        local event, a = os.pullEventRaw()

        if event == "char" then
            if type(a) == "string" and #a == 1 then
                if a:match("[%d%.-]") then
                    values[active] =
                        values[active] .. a

                    drawTargetInput(
                        values,
                        active
                    )
                end
            end

        elseif event == "key" then

            if a == keys.backspace then
                values[active] =
                    values[active]:sub(1, -2)

                drawTargetInput(
                    values,
                    active
                )

            elseif a == keys.enter then

                if values[active] == ""
                    or tonumber(values[active]) == nil then

                    writeLine(
                        15,
                        "ERROR: INVALID COORDINATE"
                    )

                    sleep(0.8)

                    drawTargetInput(
                        values,
                        active
                    )

                elseif active < 3 then

                    active = active + 1

                    drawTargetInput(
                        values,
                        active
                    )

                else
                    local x = tonumber(values[1])
                    local y = tonumber(values[2])
                    local z = tonumber(values[3])

                    state.target.x = x
                    state.target.y = y
                    state.target.z = z
                    state.target.set = true

                    state.target.revision =
                        (tonumber(state.target.revision) or 0) + 1

                    local ok, err =
                        saveTarget(state)

                    if not ok then
                        writeLine(
                            15,
                            "ERROR: " .. tostring(err)
                        )

                        sleep(1)

                        drawTargetInput(
                            values,
                            active
                        )
                    else
                        draw(state)
                    end

                    return
                end

            elseif a == keys.r then
                draw(state)
                return
            end

        elseif event == "terminate" then
            state.system.running = false
            return
        end
    end
end

--------------------------------------------------
-- PAGE SELECTION
--------------------------------------------------

local function selectPage(state, newPage)
    if newPage < 1 then
        newPage = 1
    end

    if newPage > 4 then
        newPage = 4
    end

    page = newPage

    draw(state)
end

--------------------------------------------------
-- KEY HANDLER
--------------------------------------------------

local function handleKey(state, key)
    if key == keys.left or key == keys.one then

        selectPage(state, 1)

    elseif key == keys.up or key == keys.two then

        selectPage(state, 2)

    elseif key == keys.right or key == keys.three then

        selectPage(state, 3)

    elseif key == keys.down or key == keys.four then

        selectPage(state, 4)

    elseif key == keys.i then

        setTarget(state)

    elseif key == keys.c then

        state.system.controlEnabled =
            not state.system.controlEnabled

        if not state.system.controlEnabled then
            state.guidance.commandX = 0
            state.guidance.commandY = 0
        end

        draw(state)

    elseif key == keys.q then

        state.system.status =
            "SHUTTING DOWN"

        state.system.controlEnabled = false
        state.system.running = false
    end
end

--------------------------------------------------
-- TOUCH
--------------------------------------------------

local function handleTouch(state, x, y)
    if y >= height - 2 then

        local slot =
            math.floor(
                (x - 1) * 4 /
                math.max(width, 1)
            ) + 1

        selectPage(state, slot)
    end
end

--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(state)
    if type(state) ~= "table" then
        error("DISPLAY: STATE TABLE REQUIRED")
    end

    openScreen()

    -- Load saved target directly into shared state.
    loadTarget(state)

    state.display.online = true

    draw(state)

    local timer = os.startTimer(0.10)

    while state.system.running do

        local event, a, b, c =
            os.pullEventRaw()

        if event == "timer"
            and a == timer then

            draw(state)

            timer = os.startTimer(0.10)

        elseif event == "key" then

            handleKey(state, a)

        elseif event == "monitor_touch" then

            handleTouch(
                state,
                b,
                c
            )

        elseif event == "terminate" then

            state.system.status =
                "SHUTTING DOWN"

            state.system.controlEnabled = false
            state.system.running = false
        end
    end

    -- Safety shutdown.
    state.system.controlEnabled = false
    state.guidance.commandX = 0
    state.guidance.commandY = 0
    state.display.online = false
end

return {
    run = run
}