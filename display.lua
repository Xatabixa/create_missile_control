-- Missile Control System Display
-- Single-folder ComputerCraft version

local function run(state)

    --------------------------------------------------
    -- DISPLAY
    --------------------------------------------------

    local monitor =
        peripheral.find("monitor")

    local screen =
        monitor or term.current()

    if monitor then
        pcall(
            monitor.setTextScale,
            0.5
        )
    end

    local width, height =
        screen.getSize()

    local page = 1

    --------------------------------------------------
    -- BASIC DISPLAY FUNCTIONS
    --------------------------------------------------

    local function clear()

        screen.setBackgroundColor(
            colors.black
        )

        screen.setTextColor(
            colors.white
        )

        screen.clear()

        screen.setCursorPos(
            1,
            1
        )
    end

    local function line(
        y,
        text
    )

        if y < 1 or y > height then
            return
        end

        text =
            tostring(
                text or ""
            )

        if #text > width then
            text =
                text:sub(
                    1,
                    width
                )
        end

        screen.setCursorPos(
            1,
            y
        )

        screen.clearLine()

        screen.write(text)
    end

    local function number(
        value,
        decimals
    )

        value =
            tonumber(value)

        if not value then
            return "---"
        end

        return string.format(
            "%." ..
            tostring(
                decimals or 1
            ) ..
            "f",
            value
        )
    end

    local function degrees(
        value
    )

        value =
            tonumber(value)

        if not value then
            return "---"
        end

        return number(
            math.deg(value),
            1
        )
    end

    --------------------------------------------------
    -- HEADER
    --------------------------------------------------

    local function header(
        title
    )

        line(
            1,
            "=== MISSILE CONTROL SYSTEM ==="
        )

        line(
            2,
            "MODE: " ..
            tostring(
                state.system.mode
            )
        )

        line(
            3,
            "[1] NAV [2] GUID [3] ENG [4] SYS"
        )

        line(
            4,
            "--------------------------------"
        )

        line(
            5,
            title
        )

        line(
            6,
            "--------------------------------"
        )
    end

    --------------------------------------------------
    -- NAVIGATION
    --------------------------------------------------

    local function navigationPage()

        local n =
            state.navigation

        clear()

        header(
            "NAVIGATION"
        )

        line(
            7,
            "STATUS: " ..
            tostring(n.status)
        )

        line(
            8,
            "GPS: " ..
            (
                n.gps
                and "ONLINE"
                or "OFFLINE"
            )
        )

        line(
            9,
            "ALTITUDE: " ..
            number(
                n.altitude,
                1
            )
        )

        line(
            10,
            "SPEED: " ..
            number(
                n.speed,
                2
            )
        )

        line(
            11,
            "VX: " ..
            number(
                n.velocity.x,
                2
            )
        )

        line(
            12,
            "VY: " ..
            number(
                n.velocity.y,
                2
            )
        )

        line(
            13,
            "VZ: " ..
            number(
                n.velocity.z,
                2
            )
        )

        line(
            15,
            "HEADING: " ..
            degrees(
                n.heading
            )
        )

        line(
            16,
            "PITCH: " ..
            degrees(
                n.pitch
            )
        )

        line(
            17,
            "ROLL: " ..
            degrees(
                n.roll
            )
        )

        line(
            19,
            "NAV TABLE: " ..
            (
                n.navigationTable
                and "ONLINE"
                or "OFFLINE"
            )
        )

        line(
            20,
            "ALT SENSOR: " ..
            (
                n.altitudeSensor
                and "ONLINE"
                or "OFFLINE"
            )
        )

        line(
            21,
            "GIMBAL: " ..
            (
                n.gimbalSensor
                and "ONLINE"
                or "OFFLINE"
            )
        )
    end

    --------------------------------------------------
    -- GUIDANCE
    --------------------------------------------------

    local function guidancePage()

        local g =
            state.guidance

        clear()

        header(
            "GUIDANCE"
        )

        line(
            7,
            "STATUS: " ..
            tostring(g.status)
        )

        line(
            8,
            "ACTIVE: " ..
            (
                g.active
                and "YES"
                or "NO"
            )
        )

        line(
            10,
            "YAW ERROR: " ..
            degrees(
                g.yawError
            )
        )

        line(
            11,
            "PITCH ERROR: " ..
            number(
                g.pitchError,
                2
            )
        )

        line(
            13,
            "COMMAND X: " ..
            number(
                g.commandX,
                3
            )
        )

        line(
            14,
            "COMMAND Y: " ..
            number(
                g.commandY,
                3
            )
        )

        line(
            16,
            "CONTROL: " ..
            (
                state.system.controlEnabled
                and "ENABLED"
                or "DISABLED"
            )
        )

        line(
            18,
            "TARGET: " ..
            (
                state.target.set
                and "SET"
                or "NOT SET"
            )
        )
    end

    --------------------------------------------------
    -- ENGINE
    --------------------------------------------------

    local function enginePage()

        local t =
            state.thruster

        local g =
            state.guidance

        clear()

        header(
            "VECTOR THRUSTER"
        )

        line(
            7,
            "STATUS: " ..
            tostring(t.status)
        )

        line(
            9,
            "GUIDANCE X: " ..
            number(
                g.commandX,
                3
            )
        )

        line(
            10,
            "GUIDANCE Y: " ..
            number(
                g.commandY,
                3
            )
        )

        line(
            12,
            "TARGET X: " ..
            number(
                t.targetVectorX,
                3
            )
        )

        line(
            13,
            "TARGET Y: " ..
            number(
                t.targetVectorY,
                3
            )
        )

        line(
            15,
            "ACTUAL X: " ..
            number(
                t.vectorX,
                3
            )
        )

        line(
            16,
            "ACTUAL Y: " ..
            number(
                t.vectorY,
                3
            )
        )

        line(
            18,
            "POWER: " ..
            number(
                t.power,
                3
            )
        )

        line(
            19,
            "THRUST: " ..
            number(
                t.thrust,
                3
            )
        )

        line(
            21,
            "CONTROL: " ..
            (
                state.system.controlEnabled
                and "ENABLED"
                or "DISABLED"
            )
        )
    end

    --------------------------------------------------
    -- SYSTEM
    --------------------------------------------------

    local function systemPage()

        clear()

        header(
            "SYSTEM"
        )

        line(
            7,
            "SYSTEM: " ..
            tostring(
                state.system.status
            )
        )

        line(
            8,
            "NAVIGATION: " ..
            (
                state.navigation.online
                and "ONLINE"
                or "OFFLINE"
            )
        )

        line(
            9,
            "GUIDANCE: " ..
            (
                state.guidance.online
                and "ONLINE"
                or "OFFLINE"
            )
        )

        line(
            10,
            "THRUSTER: " ..
            (
                state.thruster.online
                and "ONLINE"
                or "OFFLINE"
            )
        )

        line(
            11,
            "DISPLAY: ONLINE"
        )

        line(
            13,
            "CONTROL: " ..
            (
                state.system.controlEnabled
                and "ENABLED"
                or "DISABLED"
            )
        )

        line(
            15,
            "TARGET: " ..
            (
                state.target.set
                and "SET"
                or "NOT SET"
            )
        )

        line(
            16,
            "X: " ..
            number(
                state.target.x,
                1
            )
        )

        line(
            17,
            "Y: " ..
            number(
                state.target.y,
                1
            )
        )

        line(
            18,
            "Z: " ..
            number(
                state.target.z,
                1
            )
        )

        line(
            21,
            "I = TARGET INPUT"
        )

        line(
            22,
            "R = RETURN"
        )
    end

    --------------------------------------------------
    -- DRAW
    --------------------------------------------------

    local function draw()

        if page == 1 then

            navigationPage()

        elseif page == 2 then

            guidancePage()

        elseif page == 3 then

            enginePage()

        elseif page == 4 then

            systemPage()

        else

            page = 1

            navigationPage()
        end

        state.display.page =
            page
    end

    --------------------------------------------------
    -- TARGET INPUT
    --------------------------------------------------

    local function targetInput()

        local values = {
            "",
            "",
            ""
        }

        local field = 1

        while true do

            clear()

            line(
                1,
                "=== TARGET COORDINATES ==="
            )

            line(
                3,
                "ENTER COORDINATES"
            )

            line(
                5,
                "X: " ..
                values[1] ..
                (
                    field == 1
                    and "_"
                    or ""
                )
            )

            line(
                6,
                "Y: " ..
                values[2] ..
                (
                    field == 2
                    and "_"
                    or ""
                )
            )

            line(
                7,
                "Z: " ..
                values[3] ..
                (
                    field == 3
                    and "_"
                    or ""
                )
            )

            line(
                10,
                "ENTER = NEXT"
            )

            line(
                11,
                "R = CANCEL"
            )

            line(
                13,
                "FIELD " ..
                tostring(field) ..
                "/3"
            )

            local event, key =
                os.pullEventRaw()

            if event == "char" then

                local c = key

                if c:match(
                    "[%d%.%-]"
                ) then

                    values[field] =
                        values[field] .. c
                end

            elseif event == "key" then

                if key ==
                    keys.backspace then

                    values[field] =
                        values[field]:sub(
                            1,
                            -2
                        )

                elseif key ==
                    keys.enter then

                    local value =
                        tonumber(
                            values[field]
                        )

                    if value == nil then

                        line(
                            15,
                            "INVALID NUMBER"
                        )

                        sleep(1)

                    elseif field < 3 then

                        field =
                            field + 1

                    else

                        local x =
                            tonumber(
                                values[1]
                            )

                        local y =
                            tonumber(
                                values[2]
                            )

                        local z =
                            tonumber(
                                values[3]
                            )

                        if x and y and z then

                            state.target.x =
                                x

                            state.target.y =
                                y

                            state.target.z =
                                z

                            state.target.set =
                                true

                            state.target.revision =
                                (
                                    state.target.revision
                                    or 0
                                ) + 1

                            local file =
                                fs.open(
                                    "target.cfg",
                                    "w"
                                )

                            if file then

                                file.write(
                                    textutils.serialize({
                                        x = x,
                                        y = y,
                                        z = z,
                                        set = true,
                                        revision =
                                            state.target.revision
                                    })
                                )

                                file.close()
                            end
                        end

                        page = 4

                        draw()

                        return
                    end

                elseif key ==
                    keys.r then

                    draw()

                    return
                end

            elseif event ==
                "terminate" then

                state.system.running =
                    false

                return
            end
        end
    end

    --------------------------------------------------
    -- KEY HANDLER
    --------------------------------------------------

    local function handleKey(
        key
    )

        if key == keys.one then

            page = 1

        elseif key == keys.two then

            page = 2

        elseif key == keys.three then

            page = 3

        elseif key == keys.four then

            page = 4

        elseif key == keys.i then

            targetInput()

            return

        elseif key == keys.r then

            page = 1
        end

        draw()
    end

    --------------------------------------------------
    -- DISPLAY PROCESS
    --------------------------------------------------

    state.display.online =
        true

    draw()

    --------------------------------------------------
    -- IMPORTANT:
    -- The display has its own refresh timer.
    -- Keyboard input is handled by the same event loop.
    --------------------------------------------------

    local timer =
        os.startTimer(0.1)

    while state.system.running do

        local event, value =
            os.pullEventRaw()

        if event == "timer"
            and value == timer then

            draw()

            timer =
                os.startTimer(0.1)

        elseif event == "key" then

            handleKey(value)

        elseif event == "terminate" then

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