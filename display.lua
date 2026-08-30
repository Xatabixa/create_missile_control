-- Missile system display
-- Single-folder ComputerCraft compatible version

local screen = nil
local width = 0
local height = 0
local page = 1

local function run(state)

    local function openScreen()

        screen =
            peripheral.find("monitor")
            or term.current()

        if type(screen.setTextScale)
            == "function" then

            pcall(
                screen.setTextScale,
                0.5
            )
        end

        width, height =
            screen.getSize()

        screen.setBackgroundColor(
            colors.black
        )

        screen.setTextColor(
            colors.white
        )
    end

    local function clear()

        screen.setBackgroundColor(
            colors.black
        )

        screen.setTextColor(
            colors.white
        )

        screen.clear()
        screen.setCursorPos(1, 1)
    end

    local function writeLine(row, text)

        if row < 1 or row > height then
            return
        end

        local value =
            tostring(text or "")

        if #value > width then
            value =
                value:sub(1, width)
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
            "%." ..
            tostring(digits or 1) ..
            "f",
            value
        )
    end

    local function angleDeg(value)

        value = tonumber(value)

        if not value then
            return "---"
        end

        return fmt(
            math.deg(value),
            1
        )
    end

    local function header(title)

        writeLine(
            1,
            "=== MISSILE CONTROL SYSTEM ==="
        )

        writeLine(
            2,
            "MODE: " ..
            tostring(state.system.mode)
        )

        writeLine(
            3,
            "[1] NAV [2] GUID [3] ENG [4] SYS"
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

    local function drawNavigation()

        clear()
        header("NAVIGATION")

        local n =
            state.navigation

        writeLine(
            7,
            "STATUS: " ..
            tostring(n.status)
        )

        writeLine(
            8,
            "POS X " ..
            fmt(n.position.x, 1) ..
            " Y " ..
            fmt(n.position.y, 1)
        )

        writeLine(
            9,
            "POS Z " ..
            fmt(n.position.z, 1) ..
            " GPS " ..
            (n.gps and "ON" or "OFF")
        )

        writeLine(
            10,
            "ALT " ..
            fmt(n.altitude, 1) ..
            " VS " ..
            fmt(n.verticalSpeed, 1)
        )

        writeLine(
            11,
            "SPEED " ..
            fmt(n.speed, 2)
        )

        writeLine(
            12,
            "HDG " ..
            angleDeg(n.heading) ..
            " PITCH " ..
            angleDeg(n.pitch)
        )

        writeLine(
            13,
            "VX " ..
            fmt(n.velocity.x, 2) ..
            " VY " ..
            fmt(n.velocity.y, 2) ..
            " VZ " ..
            fmt(n.velocity.z, 2)
        )

        writeLine(
            15,
            "NAV TABLE: " ..
            (n.navigationTable
                and "ON"
                or "OFF")
        )

        writeLine(
            16,
            "ALT SENSOR: " ..
            (n.altitudeSensor
                and "ON"
                or "OFF")
        )

        writeLine(
            17,
            "GIMBAL: " ..
            (n.gimbalSensor
                and "ON"
                or "OFF")
        )

        writeLine(
            19,
            "TARGET: " ..
            (n.hasNavTarget
                and "LOCKED"
                or "NO LOCK")
        )

        writeLine(
            20,
            "DIST: " ..
            fmt(n.distance, 1) ..
            " m"
        )

        writeLine(
            21,
            "BEARING: " ..
            angleDeg(n.bearing) ..
            " deg"
        )
    end

    local function drawGuidance()

        clear()
        header("GUIDANCE")

        local g =
            state.guidance

        local n =
            state.navigation

        writeLine(
            7,
            "STATUS: " ..
            tostring(g.status)
        )

        writeLine(
            8,
            "ACTIVE: " ..
            (g.active
                and "YES"
                or "NO")
        )

        writeLine(
            9,
            "TARGET: " ..
            (n.hasNavTarget
                and "LOCKED"
                or "NO LOCK")
        )

        writeLine(
            11,
            "BEARING ERROR: " ..
            angleDeg(g.yawError)
        )

        writeLine(
            12,
            "VERT OFFSET: " ..
            fmt(g.pitchError, 2)
        )

        writeLine(
            14,
            "COMMAND X: " ..
            fmt(g.commandX, 3)
        )

        writeLine(
            15,
            "COMMAND Y: " ..
            fmt(g.commandY, 3)
        )

        writeLine(
            17,
            "CONTROL: " ..
            (state.system.controlEnabled
                and "ENABLED"
                or "DISABLED")
        )
    end

    local function drawEngine()

        clear()
        header("VECTOR THRUSTER")

        local t =
            state.thruster

        writeLine(
            7,
            "STATUS: " ..
            tostring(t.status)
        )

        writeLine(
            9,
            "COMMAND X: " ..
            fmt(
                state.guidance.commandX,
                3
            )
        )

        writeLine(
            10,
            "COMMAND Y: " ..
            fmt(
                state.guidance.commandY,
                3
            )
        )

        writeLine(
            12,
            "TARGET X: " ..
            fmt(t.targetVectorX, 3)
        )

        writeLine(
            13,
            "TARGET Y: " ..
            fmt(t.targetVectorY, 3)
        )

        writeLine(
            15,
            "ACTUAL X: " ..
            fmt(t.vectorX, 3)
        )

        writeLine(
            16,
            "ACTUAL Y: " ..
            fmt(t.vectorY, 3)
        )

        writeLine(
            18,
            "POWER: " ..
            fmt(t.power, 3)
        )

        writeLine(
            19,
            "THRUST: " ..
            fmt(t.thrust, 3)
        )

        writeLine(
            21,
            "CONTROL: " ..
            (state.system.controlEnabled
                and "ENABLED"
                or "LOCKED")
        )
    end

    local function drawSystem()

        clear()
        header("SYSTEM")

        writeLine(
            7,
            "SYSTEM: " ..
            tostring(state.system.status)
        )

        writeLine(
            8,
            "NAVIGATION " ..
            (state.navigation.online
                and "ONLINE"
                or "OFFLINE")
        )

        writeLine(
            9,
            "GUIDANCE " ..
            (state.guidance.online
                and "ONLINE"
                or "OFFLINE")
        )

        writeLine(
            10,
            "THRUSTER " ..
            (state.thruster.online
                and "ONLINE"
                or "OFFLINE")
        )

        writeLine(
            11,
            "DISPLAY ONLINE"
        )

        writeLine(
            13,
            "CONTROL: " ..
            (state.system.controlEnabled
                and "ENABLED"
                or "DISABLED")
        )

        writeLine(
            14,
            "TARGET: " ..
            (state.target.set
                and "SET"
                or "NOT SET")
        )

        writeLine(
            15,
            "X " ..
            fmt(state.target.x, 1) ..
            " Y " ..
            fmt(state.target.y, 1)
        )

        writeLine(
            16,
            "Z " ..
            fmt(state.target.z, 1)
        )

        writeLine(
            19,
            "I = TARGET"
        )

        writeLine(
            20,
            "Q = SHUTDOWN"
        )
    end

    local function draw()

        state.display.page =
            page

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

    local function targetInput()

        local values = {
            "",
            "",
            ""
        }

        local active = 1

        while true do

            clear()

            writeLine(
                1,
                "=== TARGET INPUT ==="
            )

            writeLine(
                4,
                "> X: " ..
                values[1]
            )

            writeLine(
                5,
                "  Y: " ..
                values[2]
            )

            writeLine(
                6,
                "  Z: " ..
                values[3]
            )

            writeLine(
                8,
                "ENTER = NEXT / SAVE"
            )

            writeLine(
                9,
                "ESC = CANCEL"
            )

            local event, a =
                os.pullEventRaw()

            if event == "char" then

                if #a == 1
                    and a:match(
                        "[%d%.%-]"
                    ) then

                    values[active] =
                        values[active] .. a

                end

            elseif event == "key" then

                if a == keys.backspace then

                    values[active] =
                        values[active]:sub(
                            1,
                            -2
                        )

                elseif a == keys.enter then

                    local number =
                        tonumber(
                            values[active]
                        )

                    if not number then

                        writeLine(
                            11,
                            "INVALID COORDINATE"
                        )

                        sleep(0.8)

                    elseif active < 3 then

                        active =
                            active + 1

                    else

                        local x =
                            tonumber(values[1])

                        local y =
                            tonumber(values[2])

                        local z =
                            tonumber(values[3])

                        local file =
                            fs.open(
                                "target.cfg",
                                "w"
                            )

                        if file then

                            local data = {
                                x = x,
                                y = y,
                                z = z,
                                set = true,
                                revision =
                                    (
                                        state.target.revision
                                        or 0
                                    ) + 1
                            }

                            file.write(
                                textutils.serialize(
                                    data
                                )
                            )

                            file.close()

                            state.target.x = x
                            state.target.y = y
                            state.target.z = z
                            state.target.set = true
                            state.target.revision =
                                data.revision
                        end

                        draw()
                        return
                    end

                elseif a == keys.escape then

                    draw()
                    return
                end
            end
        end
    end

    local function handleKey(key)

        if key == keys.one then
            page = 1
            draw()

        elseif key == keys.two then
            page = 2
            draw()

        elseif key == keys.three then
            page = 3
            draw()

        elseif key == keys.four then
            page = 4
            draw()

        elseif key == keys.i then
            targetInput()

        elseif key == keys.q then

            state.system.status =
                "SHUTTING DOWN"

            state.system.running =
                false
        end
    end

    openScreen()

    state.display.online =
        true

    draw()

    local timer =
        os.startTimer(0.10)

    while state.system.running do

        local event, a =
            os.pullEventRaw()

        if event == "timer"
            and a == timer then

            draw()

            timer =
                os.startTimer(0.10)

        elseif event == "key" then

            handleKey(a)

        elseif event == "terminate" then

            state.system.status =
                "SHUTTING DOWN"

            state.system.running =
                false
        end
    end

    state.display.online =
        false
end

return {
    run = run
}