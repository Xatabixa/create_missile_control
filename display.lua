-- Missile Control System Display
-- CC:Tweaked
--
-- 1 = Navigation
-- 2 = Guidance
-- 3 = Engine
-- 4 = System
--
-- I = target coordinates
-- S = start position
-- C = control
-- Q = shutdown

--------------------------------------------------
-- SCREEN
--------------------------------------------------

local screen =
    peripheral.find("monitor")
    or term.current()

local width,
height =
    screen.getSize()

local page = 1

local TARGET_FILE = "target.cfg"
local START_FILE = "start.cfg"


--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

if type(screen.setTextScale) == "function" then
    pcall(
        screen.setTextScale,
        0.5
    )
end

screen.setBackgroundColor(colors.black)
screen.setTextColor(colors.white)


--------------------------------------------------
-- BASIC FUNCTIONS
--------------------------------------------------

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

local function deg(value)

    value = tonumber(value)

    if not value then
        return "---"
    end

    return fmt(
        math.deg(value),
        1
    )
end

local function online(value)

    if value == true then
        return "ONLINE"
    end

    return "OFF"
end


--------------------------------------------------
-- HEADER
--------------------------------------------------

local function header(state, title)

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
        "I=TGT S=START C=CTRL"
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
-- SAVE TARGET
--------------------------------------------------

local function saveTarget(state)

    local file =
        fs.open(
            TARGET_FILE,
            "w"
        )

    if not file then
        return false
    end

    file.write(
        textutils.serialize({
            x = tonumber(state.target.x) or 0,
            y = tonumber(state.target.y) or 0,
            z = tonumber(state.target.z) or 0,
            set = state.target.set == true,
            revision =
                tonumber(
                    state.target.revision
                ) or 0
        })
    )

    file.close()

    return true
end


--------------------------------------------------
-- SAVE START
--------------------------------------------------

local function saveStart(state)

    local file =
        fs.open(
            START_FILE,
            "w"
        )

    if not file then
        return false
    end

    file.write(
        textutils.serialize({
            x =
                tonumber(
                    state.startPosition.x
                ) or 0,

            y =
                tonumber(
                    state.startPosition.y
                ) or 0,

            z =
                tonumber(
                    state.startPosition.z
                ) or 0,

            set =
                state.startPosition.set
                == true
        })
    )

    file.close()

    return true
end


--------------------------------------------------
-- LOAD TARGET
--------------------------------------------------

local function loadTarget(state)

    if not fs.exists(TARGET_FILE) then
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

    if type(data) ~= "table" then
        return
    end

    state.target.x =
        tonumber(data.x) or 0

    state.target.y =
        tonumber(data.y) or 0

    state.target.z =
        tonumber(data.z) or 0

    state.target.set =
        data.set == true

    state.target.revision =
        tonumber(data.revision) or 0
end


--------------------------------------------------
-- LOAD START
--------------------------------------------------

local function loadStart(state)

    if not fs.exists(START_FILE) then
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

    if type(data) ~= "table" then
        return
    end

    state.startPosition.x =
        tonumber(data.x) or 0

    state.startPosition.y =
        tonumber(data.y) or 0

    state.startPosition.z =
        tonumber(data.z) or 0

    state.startPosition.set =
        data.set == true
end


--------------------------------------------------
-- NAVIGATION PAGE
--------------------------------------------------

local function drawNavigation(state)

    clear()

    header(
        state,
        "NAVIGATION"
    )

    local n =
        state.navigation or {}

    local p =
        n.position or {
            x = 0,
            y = 0,
            z = 0
        }

    local v =
        n.velocity or {
            x = 0,
            y = 0,
            z = 0
        }

    writeLine(
        7,
        "STATUS: " ..
        tostring(
            n.status or "OFFLINE"
        )
    )

    writeLine(
        8,
        "POS X " ..
        fmt(p.x, 1) ..
        " Y " ..
        fmt(p.y, 1)
    )

    writeLine(
        9,
        "POS Z " ..
        fmt(p.z, 1)
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
        fmt(n.speed, 2) ..
        " m/s"
    )

    writeLine(
        12,
        "HDG " ..
        deg(n.heading) ..
        " P " ..
        deg(n.pitch) ..
        " R " ..
        deg(n.roll)
    )

    writeLine(
        13,
        "VX " ..
        fmt(v.x, 2) ..
        " VY " ..
        fmt(v.y, 2)
    )

    writeLine(
        14,
        "VZ " ..
        fmt(v.z, 2)
    )

    writeLine(
        15,
        "ANG X " ..
        fmt(n.angularRateX, 2) ..
        " Y " ..
        fmt(n.angularRateY, 2)
    )

    writeLine(
        16,
        "ANG Z " ..
        fmt(n.angularRateZ, 2)
    )

    writeLine(
        17,
        "DIST " ..
        fmt(n.distance, 1)
    )

    writeLine(
        18,
        "BEARING " ..
        deg(n.bearing)
    )

    writeLine(
        19,
        "ELEVATION " ..
        deg(n.elevation)
    )

    writeLine(
        21,
        "NAV TABLE: " ..
        online(
            n.navigationTable
        )
    )

    writeLine(
        22,
        "NAV TARGET: " ..
        tostring(
            n.navigationTargetStatus
            or "UNKNOWN"
        )
    )

    writeLine(
        23,
        "ALT: " ..
        online(
            n.altitudeSensor
        ) ..
        " GIM: " ..
        online(
            n.gimbalSensor
        )
    )

    writeLine(
        24,
        "VEL: " ..
        online(
            n.velocitySensor
        )
    )
end


--------------------------------------------------
-- GUIDANCE PAGE
--------------------------------------------------

local function drawGuidance(state)

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
        "STATUS: " ..
        tostring(
            g.status or "OFFLINE"
        )
    )

    writeLine(
        8,
        "ACTIVE: " ..
        (
            g.active
            and "YES"
            or "NO"
        )
    )

    writeLine(
        9,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ON"
            or "OFF"
        )
    )

    writeLine(
        10,
        "MANUAL TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

    writeLine(
        11,
        "NAV TARGET: " ..
        tostring(
            n.navigationTargetStatus
            or "UNKNOWN"
        )
    )

    writeLine(
        12,
        "DIST: " ..
        fmt(
            n.distance,
            1
        )
    )

    writeLine(
        13,
        "YAW ERR: " ..
        deg(
            g.yawError
        )
    )

    writeLine(
        14,
        "PITCH ERR: " ..
        deg(
            g.pitchError
        )
    )

    writeLine(
        15,
        "YAW RATE: " ..
        deg(
            g.yawRate
        )
    )

    writeLine(
        16,
        "PITCH RATE: " ..
        deg(
            g.pitchRate
        )
    )

    writeLine(
        17,
        "PITCH CMD: " ..
        fmt(
            g.commandX,
            3
        )
    )

    writeLine(
        18,
        "YAW CMD: " ..
        fmt(
            g.commandY,
            3
        )
    )

    writeLine(
        19,
        "YAW P " ..
        fmt(g.yawP, 3) ..
        " D " ..
        fmt(g.yawD, 3)
    )

    writeLine(
        20,
        "PITCH P " ..
        fmt(g.pitchP, 3) ..
        " D " ..
        fmt(g.pitchD, 3)
    )

    writeLine(
        21,
        "YAW I " ..
        fmt(g.yawI, 4)
    )

    writeLine(
        22,
        "PITCH I " ..
        fmt(g.pitchI, 4)
    )

    writeLine(
        23,
        "TARGET BRG " ..
        deg(
            g.targetBearing
        )
    )

    writeLine(
        24,
        "TARGET ELV " ..
        deg(
            g.targetElevation
        )
    )
end


--------------------------------------------------
-- ENGINE PAGE
--------------------------------------------------

local function drawEngine(state)

    clear()

    header(
        state,
        "VECTOR THRUSTER"
    )

    local t =
        state.thruster or {}

    local g =
        state.guidance or {}

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
        tostring(found)
    )

    writeLine(
        8,
        "COMMAND SENT: " ..
        tostring(commanded) ..
        "/" ..
        tostring(found)
    )

    writeLine(
        9,
        "STATUS: " ..
        tostring(
            t.status or "OFFLINE"
        )
    )

    writeLine(
        10,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ENABLED"
            or "DISABLED"
        )
    )

    writeLine(
        11,
        "CMD X: " ..
        fmt(g.commandX, 3)
    )

    writeLine(
        12,
        "CMD Y: " ..
        fmt(g.commandY, 3)
    )

    writeLine(
        13,
        "TARGET X: " ..
        fmt(t.targetVectorX, 3)
    )

    writeLine(
        14,
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
        17,
        "POWER: " ..
        fmt(t.power, 3)
    )

    writeLine(
        18,
        "THRUST: " ..
        fmt(t.thrust, 3)
    )

    local engines =
        t.engines or {}

    for i = 1,
        math.min(
            #engines,
            4
        ) do

        local entry =
            engines[i]

        local name = "---"

        if type(entry) ==
            "table" then

            name =
                tostring(
                    entry.name
                    or "---"
                )

        else

            name =
                tostring(
                    entry
                    or "---"
                )

        end

        writeLine(
            18 + i,
            "E" ..
            tostring(i) ..
            ": " ..
            name
        )

    end

    if next(
        t.commandErrors or {}
    ) ~= nil then

        writeLine(
            24,
            "COMMAND ERROR"
        )

    else

        writeLine(
            24,
            "[C] CONTROL ON/OFF"
        )

    end
end


--------------------------------------------------
-- SYSTEM PAGE
--------------------------------------------------

local function drawSystem(state)

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

    local f =
        state.flight or {}


    --------------------------------------------------
    -- CORE STATUS
    --------------------------------------------------

    writeLine(
        7,
        "SYSTEM: " ..
        tostring(
            state.system.status
        )
    )

    writeLine(
        8,
        "NAV: " ..
        online(
            n.online
        )
    )

    writeLine(
        9,
        "GUIDANCE: " ..
        online(
            g.online
        )
    )

    writeLine(
        10,
        "THRUSTER: " ..
        online(
            t.online
        )
    )

    writeLine(
        11,
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ON"
            or "OFF"
        )
    )

    writeLine(
        12,
        "FLIGHT: " ..
        tostring(
            f.phase
            or "READY"
        )
    )


    --------------------------------------------------
    -- DEVICES
    --------------------------------------------------

    writeLine(
        14,
        "NAV TABLE: " ..
        online(
            n.navigationTable
        )
    )

    writeLine(
        15,
        "NAV TARGET: " ..
        tostring(
            n.navigationTargetStatus
            or "UNKNOWN"
        )
    )

    writeLine(
        16,
        "ALT SENSOR: " ..
        online(
            n.altitudeSensor
        )
    )

    writeLine(
        17,
        "GIMBAL: " ..
        online(
            n.gimbalSensor
        )
    )

    writeLine(
        18,
        "VELOCITY: " ..
        online(
            n.velocitySensor
        )


    --------------------------------------------------
    -- MANUAL TARGET
    --------------------------------------------------

    writeLine(
        20,
        "MANUAL TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

    writeLine(
        21,
        "TARGET X: " ..
        fmt(
            state.target.x,
            0
        )
    )

    writeLine(
        22,
        "TARGET Y: " ..
        fmt(
            state.target.y,
            0
        )
    )

    writeLine(
        23,
        "TARGET Z: " ..
        fmt(
            state.target.z,
            0
        )
    )

    writeLine(
        24,
        "ENGINES: " ..
        tostring(
            t.engineCount
            or 0
        ) ..
        " CMD " ..
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

end


--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw(state)

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
            "ENTER COORDINATES"
        )

        writeLine(
            7,
            (
                active == 1
                and "> "
                or "  "
            ) ..
            "X: " ..
            values[1]
        )

        writeLine(
            8,
            (
                active == 2
                and "> "
                or "  "
            ) ..
            "Y: " ..
            values[2]
        )

        writeLine(
            9,
            (
                active == 3
                and "> "
                or "  "
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


    redraw()


    while true do

        local event,
        a =
            os.pullEventRaw()


        if event == "char" then

            if type(a) == "string"
                and
                a:match(
                    "[%d%.-]"
                ) then

                values[active] =
                    values[active] ..
                    a

                redraw()

            end


        elseif event == "key" then

            if a ==
                keys.backspace then

                values[active] =
                    values[active]:sub(
                        1,
                        -2
                    )

                redraw()


            elseif a ==
                keys.enter then

                if not tonumber(
                    values[active]
                ) then

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


            elseif a == keys.r then

                return

            end


        elseif event == "terminate" then

            state.system.running =
                false

            return

        end

    end

end


--------------------------------------------------
-- TARGET INPUT
--------------------------------------------------

local function setTarget(state)

    coordinateInput(
        state,
        "MANUAL TARGET",
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

            saveTarget(
                state
            )

            draw(
                state
            )

        end
    )

end


--------------------------------------------------
-- START INPUT
--------------------------------------------------

local function setStart(state)

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

            saveStart(
                state
            )

            draw(
                state
            )

        end
    )

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

        if state.system.controlEnabled then

            state.system.status =
                "CONTROL ENABLED"

        else

            state.system.status =
                "ONLINE"

            if state.guidance then

                state.guidance.commandX =
                    0

                state.guidance.commandY =
                    0

            end

        end

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

local function run(state)

    state.display =
        state.display or {}


    state.display.online =
        true


    --------------------------------------------------
    -- Important:
    -- target.lua is responsible for loading target.
    -- We don't overwrite state.target here.
    --------------------------------------------------

    loadStart(
        state
    )


    draw(
        state
    )


    while state.system
        and
        state.system.running do

        local event,
        a =
            os.pullEventRaw()


        if event == "key" then

            handleKey(
                state,
                a
            )


        elseif event == "terminate" then

            state.system.controlEnabled =
                false

            state.system.running =
                false

        end

    end


    state.system.controlEnabled =
        false


    if state.guidance then

        state.guidance.commandX =
            0

        state.guidance.commandY =
            0

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