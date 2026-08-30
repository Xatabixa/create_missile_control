-- Missile Control System Display
-- CC:Tweaked
--
-- Pages:
-- 1 Navigation
-- 2 Guidance
-- 3 Engine
-- 4 System
--
-- Keys:
-- 1-4  page
-- I    target input
-- S    start position
-- C    control
-- Q    shutdown
-- R    cancel input

--------------------------------------------------
-- DISPLAY
--------------------------------------------------

local screen =
    peripheral.find("monitor")
    or term.current()


local width,
height =
    screen.getSize()


local page =
    1


--------------------------------------------------
-- FILES
--------------------------------------------------

local TARGET_FILE =
    "target.cfg"

local START_FILE =
    "start.cfg"


--------------------------------------------------
-- INIT
--------------------------------------------------

if type(screen.setTextScale)
    == "function" then

    pcall(
        screen.setTextScale,
        0.5
    )

end


screen.setBackgroundColor(
    colors.black
)

screen.setTextColor(
    colors.white
)


--------------------------------------------------
-- CLEAR
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


--------------------------------------------------
-- WRITE
--------------------------------------------------

local function writeLine(
    row,
    text
)

    if row < 1
        or row > height then

        return

    end


    local value =
        tostring(
            text or ""
        )


    if #value > width then

        value =
            value:sub(
                1,
                width
            )

    end


    screen.setCursorPos(
        1,
        row
    )


    screen.clearLine()


    screen.write(
        value
    )

end


--------------------------------------------------
-- FORMAT
--------------------------------------------------

local function fmt(
    value,
    digits
)

    value =
        tonumber(value)


    if not value then

        return "---"

    end


    return string.format(
        "%." ..
        tostring(
            digits or 1
        ) ..
        "f",
        value
    )

end


--------------------------------------------------
-- ANGLE
--------------------------------------------------

local function deg(
    value
)

    value =
        tonumber(value)


    if not value then

        return "---"

    end


    return fmt(
        math.deg(value),
        1
    )

end


--------------------------------------------------
-- HEADER
--------------------------------------------------

local function header(
    state,
    title
)

    writeLine(
        1,
        "=== MISSILE CONTROL ==="
    )


    writeLine(
        2,
        "MODE: " ..
        tostring(
            state.system.mode
        )
    )


    writeLine(
        3,
        "[1]NAV [2]GUID [3]ENG [4]SYS"
    )


    writeLine(
        4,
        "I=TARGET S=START C=CONTROL"
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

local function drawNavigation(
    state
)

    clear()


    header(
        state,
        "NAVIGATION"
    )


    local n =
        state.navigation or {}


    local p =
        n.position or {}


    local v =
        n.velocity or {}


    writeLine(
        7,
        "STATUS " ..
        tostring(
            n.status
        )
    )


    writeLine(
        8,
        "POS X " ..
        fmt(
            p.x,
            1
        ) ..
        " Y " ..
        fmt(
            p.y,
            1
        )
    )


    writeLine(
        9,
        "POS Z " ..
        fmt(
            p.z,
            1
        )
    )


    writeLine(
        10,
        "ALT " ..
        fmt(
            n.altitude,
            1
        ) ..
        " VS " ..
        fmt(
            n.verticalSpeed,
            1
        )
    )


    writeLine(
        11,
        "SPEED " ..
        fmt(
            n.speed,
            2
        ) ..
        " m/s"
    )


    writeLine(
        12,
        "HDG " ..
        deg(
            n.heading
        ) ..
        " P " ..
        deg(
            n.pitch
        ) ..
        " R " ..
        deg(
            n.roll
        )
    )


    writeLine(
        13,
        "VX " ..
        fmt(
            v.x,
            2
        ) ..
        " VY " ..
        fmt(
            v.y,
            2
        )
    )


    writeLine(
        14,
        "VZ " ..
        fmt(
            v.z,
            2
        )
    )


    writeLine(
        15,
        "ANG X " ..
        fmt(
            n.angularRateX,
            2
        ) ..
        " Y " ..
        fmt(
            n.angularRateY,
            2
        )
    )


    writeLine(
        16,
        "ANG Z " ..
        fmt(
            n.angularRateZ,
            2
        )
    )


    writeLine(
        17,
        "ACC X " ..
        fmt(
            n.accelerationX,
            2
        ) ..
        " Y " ..
        fmt(
            n.accelerationY,
            2
        )
    )


    writeLine(
        18,
        "ACC Z " ..
        fmt(
            n.accelerationZ,
            2
        )
    )


    writeLine(
        19,
        "BEARING " ..
        deg(
            n.bearing
        )
    )


    writeLine(
        20,
        "ELEVATION " ..
        deg(
            n.elevation
        )
    )


    writeLine(
        21,
        "DIST " ..
        fmt(
            n.distance,
            1
        ) ..
        " m"
    )


    writeLine(
        22,
        "CLOSURE " ..
        fmt(
            n.closureRate,
            2
        )
    )


    writeLine(
        23,
        "NAV TABLE " ..
        (
            n.navigationTable
            and "ONLINE"
            or "OFFLINE"
        )
    )


    writeLine(
        24,
        "GIMBAL " ..
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

local function drawGuidance(
    state
)

    clear()


    header(
        state,
        "GUIDANCE"
    )


    local g =
        state.guidance or {}


    local n =
        state.navigation or {}


    writeLine(
        7,
        "STATUS " ..
        tostring(
            g.status
        )
    )


    writeLine(
        8,
        "ACTIVE " ..
        (
            g.active
            and "YES"
            or "NO"
        )
    )


    writeLine(
        9,
        "CONTROL " ..
        (
            state.system.controlEnabled
            and "ON"
            or "OFF"
        )
    )


    writeLine(
        10,
        "PHASE " ..
        tostring(
            g.flightPhase
            or "READY"
        )
    )


    writeLine(
        11,
        "DIST " ..
        fmt(
            n.distance,
            1
        ) ..
        " m"
    )


    writeLine(
        12,
        "YAW ERR " ..
        deg(
            g.yawError
        )
    )


    writeLine(
        13,
        "PITCH ERR " ..
        deg(
            g.pitchError
        )
    )


    writeLine(
        14,
        "YAW RATE " ..
        deg(
            g.yawRate
        ) ..
        "/s"
    )


    writeLine(
        15,
        "PITCH RATE " ..
        deg(
            g.pitchRate
        ) ..
        "/s"
    )


    writeLine(
        16,
        "PITCH CMD " ..
        fmt(
            g.commandX,
            3
        )
    )


    writeLine(
        17,
        "YAW CMD " ..
        fmt(
            g.commandY,
            3
        )
    )


    writeLine(
        18,
        "YAW P " ..
        fmt(
            g.yawP,
            3
        ) ..
        " D " ..
        fmt(
            g.yawD,
            3
        )
    )


    writeLine(
        19,
        "PITCH P " ..
        fmt(
            g.pitchP,
            3
        ) ..
        " D " ..
        fmt(
            g.pitchD,
            3
        )
    )


    writeLine(
        20,
        "YAW I " ..
        fmt(
            g.yawI,
            4
        )
    )


    writeLine(
        21,
        "PITCH I " ..
        fmt(
            g.pitchI,
            4
        )
    )


    writeLine(
        22,
        "TARGET BRG " ..
        deg(
            g.targetBearing
        )
    )


    writeLine(
        23,
        "TARGET ELV " ..
        deg(
            g.targetElevation
        )
    )


    writeLine(
        24,
        "MAX VECTOR " ..
        fmt(
            g.flightMaxVector,
            3
        )

    )

end


--------------------------------------------------
-- ENGINE
--------------------------------------------------

local function drawEngine(
    state
)

    clear()


    header(
        state,
        "VECTOR THRUSTER"
    )


    local t =
        state.thruster or {}


    local g =
        state.guidance or {}


    --------------------------------------------------
    -- ENGINE COUNT
    --------------------------------------------------

    local found =
        tonumber(
            t.engineCount
        ) or 0


    local commanded =
        tonumber(
            t.commandedEngines
        ) or 0


    writeLine(
        7,
        "ENGINES FOUND: " ..
        tostring(
            found
        )
    )


    writeLine(
        8,
        "COMMAND SENT: " ..
        tostring(
            commanded
        ) ..
        "/" ..
        tostring(
            found
        )
    )


    writeLine(
        9,
        "STATUS: " ..
        tostring(
            t.status
        )
    )


    writeLine(
        10,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ENABLED"
            or "LOCKED"
        )
    )


    writeLine(
        11,
        "COMMAND X: " ..
        fmt(
            g.commandX,
            3
        )
    )


    writeLine(
        12,
        "COMMAND Y: " ..
        fmt(
            g.commandY,
            3
        )
    )


    writeLine(
        13,
        "TARGET X: " ..
        fmt(
            t.targetVectorX,
            3
        )
    )


    writeLine(
        14,
        "TARGET Y: " ..
        fmt(
            t.targetVectorY,
            3
        )
    )


    writeLine(
        15,
        "ACTUAL X: " ..
        fmt(
            t.vectorX,
            3
        )
    )


    writeLine(
        16,
        "ACTUAL Y: " ..
        fmt(
            t.vectorY,
            3
        )
    )


    writeLine(
        17,
        "POWER: " ..
        fmt(
            t.power,
            3
        )
    )


    writeLine(
        18,
        "THRUST: " ..
        fmt(
            t.thrust,
            3
        )
    )


    --------------------------------------------------
    -- ENGINE NAMES
    --------------------------------------------------

    local engines =
        t.engines or {}


    local row =
        19


    for i = 1, math.min(
        #engines,
        4
    ) do

        local entry =
            engines[i]


        if type(entry) ==
            "table" then

            writeLine(
                row,
                "E" ..
                tostring(i) ..
                ": " ..
                tostring(
                    entry.name
                    or "---"
                )
            )

        else

            writeLine(
                row,
                "E" ..
                tostring(i) ..
                ": " ..
                tostring(
                    entry
                )
            )

        end


        row =
            row + 1

    end


    if next(
        t.commandErrors
        or {}
    ) ~= nil then

        writeLine(
            24,
            "ERROR: COMMAND FAILED"
        )

    else

        writeLine(
            24,
            "[C] CONTROL ON/OFF"
        )

    end

end


--------------------------------------------------
-- SYSTEM
--------------------------------------------------

local function drawSystem(
    state
)

    clear()


    header(
        state,
        "SYSTEM"
    )


    local n =
        state.navigation or {}


    local g =
        state.guidance or {}


    local t =
        state.thruster or {}


    writeLine(
        7,
        "SYSTEM " ..
        tostring(
            state.system.status
        )
    )


    writeLine(
        8,
        "NAVIGATION " ..
        (
            n.online
            and "ONLINE"
            or "OFFLINE"
        )
    )


    writeLine(
        9,
        "GUIDANCE " ..
        (
            g.online
            and "ONLINE"
            or "OFFLINE"
        )
    )


    writeLine(
        10,
        "THRUSTER " ..
        (
            t.online
            and "ONLINE"
            or "OFFLINE"
        )
    )


    writeLine(
        11,
        "CONTROL " ..
        (
            state.system.controlEnabled
            and "ENABLED"
            or "DISABLED"
        )
    )


    writeLine(
        13,
        "TARGET " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )


    writeLine(
        14,
        "TX " ..
        fmt(
            state.target.x,
            1
        ) ..
        " TY " ..
        fmt(
            state.target.y,
            1
        )
    )


    writeLine(
        15,
        "TZ " ..
        fmt(
            state.target.z,
            1
        )
    )


    writeLine(
        17,
        "START " ..
        (
            state.startPosition.set
            and "SET"
            or "NOT SET"
        )
    )


    writeLine(
        18,
        "SX " ..
        fmt(
            state.startPosition.x,
            1
        )
    )


    writeLine(
        19,
        "SY " ..
        fmt(
            state.startPosition.y,
            1
        )
    )


    writeLine(
        20,
        "SZ " ..
        fmt(
            state.startPosition.z,
            1
        )
    )


    writeLine(
        22,
        "ENGINES " ..
        tostring(
            t.engineCount
            or 0
        )
    )


    writeLine(
        23,
        "COMMAND " ..
        tostring(
            t.commandedEngines
            or 0
        ) ..
        "/" ..
        tostring(
            t.engineCount
            or 0
        )
    )


    if state.system.error then

        writeLine(
            24,
            "ERROR: " ..
            tostring(
                state.system.error
            )
        )

    else

        writeLine(
            24,
            "I=TARGET S=START C=CONTROL"
        )

    end

end


--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw(
    state
)

    if page == 1 then

        drawNavigation(
            state
        )

    elseif page == 2 then

        drawGuidance(
            state
        )

    elseif page == 3 then

        drawEngine(
            state
        )

    else

        drawSystem(
            state
        )

    end

end


--------------------------------------------------
-- COORDINATE INPUT
--------------------------------------------------

local function coordinateInput(
    state,
    title,
    callback
)

    local values = {
        "",
        "",
        ""
    }


    local active = 1


    local function redraw()

        clear()


        writeLine(
            1,
            "=== MISSILE CONTROL ==="
        )


        writeLine(
            2,
            title
        )


        writeLine(
            3,
            "--------------------------------"
        )


        writeLine(
            5,
            "Enter coordinates:"
        )


        for i = 1, 3 do

            writeLine(
                6 + i,
                (
                    active == i
                    and "> "
                    or "  "
                ) ..
                (
                    i == 1
                    and "X: "
                    or
                    i == 2
                    and "Y: "
                    or
                    "Z: "
                ) ..
                values[i]
            )

        end


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


    redraw()


    while true do

        local event,
        a =
            os.pullEventRaw()


        --------------------------------------------------
        -- CHARACTER
        --------------------------------------------------

        if event ==
            "char" then

            if type(a) ==
                "string"
                and
                a:match(
                    "[%d%.-]"
                ) then

                values[active] =
                    values[active] ..
                    a

                redraw()

            end


        --------------------------------------------------
        -- KEY
        --------------------------------------------------

        elseif event ==
            "key" then


            --------------------------------------------------
            -- BACKSPACE
            --------------------------------------------------

            if a ==
                keys.backspace then

                values[active] =
                    values[active]:sub(
                        1,
                        -2
                    )

                redraw()


            --------------------------------------------------
            -- ENTER
            --------------------------------------------------

            elseif a ==
                keys.enter then

                local number =
                    tonumber(
                        values[active]
                    )


                if not number then

                    writeLine(
                        15,
                        "INVALID COORDINATE"
                    )


                    sleep(
                        0.8
                    )


                    redraw()

                elseif active < 3 then

                    active =
                        active + 1

                    redraw()

                else

                    callback(
                        tonumber(values[1]),
                        tonumber(values[2]),
                        tonumber(values[3])
                    )

                    return

                end


            --------------------------------------------------
            -- CANCEL
            --------------------------------------------------

            elseif a ==
                keys.r then

                draw(
                    state
                )

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
-- TARGET
--------------------------------------------------

local function setTarget(
    state
)

    coordinateInput(
        state,
        "TARGET COORDINATES",
        function(x, y, z)

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
                    tonumber(
                        state.target.revision
                    ) or 0
                ) + 1


            local file =
                fs.open(
                    TARGET_FILE,
                    "w"
                )


            if file then

                file.write(
                    textutils.serialize(
                        {
                            x = x,
                            y = y,
                            z = z,
                            set = true,
                            revision =
                                state.target.revision
                        }
                    )
                )

                file.close()

            end


            draw(
                state
            )

        end
    )

end


--------------------------------------------------
-- START POSITION
--------------------------------------------------

local function setStart(
    state
)

    coordinateInput(
        state,
        "START POSITION",
        function(x, y, z)

            state.startPosition.x =
                x

            state.startPosition.y =
                y

            state.startPosition.z =
                z

            state.startPosition.set =
                true


            local file =
                fs.open(
                    START_FILE,
                    "w"
                )


            if file then

                file.write(
                    textutils.serialize(
                        {
                            x = x,
                            y = y,
                            z = z,
                            set = true
                        }
                    )
                )

                file.close()

            end


            draw(
                state
            )

        end
    )

end


--------------------------------------------------
-- LOAD TARGET
--------------------------------------------------

local function loadTarget(
    state
)

    if not fs.exists(
        TARGET_FILE
    ) then

        return

    end


    local file =
        fs.open(
            TARGET_FILE,
            "r"
        )


    if not file then

        return

    end


    local data =
        textutils.unserialize(
            file.readAll()
        )


    file.close()


    if type(data) ==
        "table" then

        state.target.x =
            tonumber(data.x)
            or 0

        state.target.y =
            tonumber(data.y)
            or 0

        state.target.z =
            tonumber(data.z)
            or 0

        state.target.set =
            data.set == true

        state.target.revision =
            tonumber(
                data.revision
            ) or 0

    end

end


--------------------------------------------------
-- LOAD START
--------------------------------------------------

local function loadStart(
    state
)

    if not fs.exists(
        START_FILE
    ) then

        return

    end


    local file =
        fs.open(
            START_FILE,
            "r"
        )


    if not file then

        return

    end


    local data =
        textutils.unserialize(
            file.readAll()
        )


    file.close()


    if type(data) ==
        "table" then

        state.startPosition.x =
            tonumber(data.x)
            or 0

        state.startPosition.y =
            tonumber(data.y)
            or 0

        state.startPosition.z =
            tonumber(data.z)
            or 0

        state.startPosition.set =
            data.set == true

    end

end


--------------------------------------------------
-- KEY HANDLER
--------------------------------------------------

local function handleKey(
    state,
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

        setTarget(
            state
        )

        return


    elseif key == keys.s then

        setStart(
            state
        )

        return


    elseif key == keys.c then

        state.system.controlEnabled =
            not state.system.controlEnabled


        draw(
            state
        )

        return


    elseif key == keys.q then

        state.system.controlEnabled =
            false

        state.system.running =
            false

        return

    end


    draw(
        state
    )

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local function run(
    state
)

    state.display =
        state.display or {}


    state.display.online =
        true


    loadTarget(
        state
    )


    loadStart(
        state
    )


    draw(
        state
    )


    while state.system
        and state.system.running do

        local event,
        a =
            os.pullEventRaw()


        if event ==
            "key" then

            handleKey(
                state,
                a
            )


        elseif event ==
            "terminate" then

            state.system.running =
                false

        end

    end


    state.display.online =
        false

end


--------------------------------------------------
-- EXPORT
--------------------------------------------------

return {
    run = run
}