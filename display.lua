-- Missile Control System Display
-- CC:Tweaked
--
-- 5 pages
-- Two-column interface
--
-- 1 = Navigation
-- 2 = Guidance
-- 3 = Engine
-- 4 = Flight
-- 5 = System
--
-- I = target coordinates
-- S = start position
-- C = control
-- Q = shutdown
-- R = cancel input

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


--------------------------------------------------
-- FILES
--------------------------------------------------

local TARGET_FILE = "target.cfg"
local START_FILE = "start.cfg"


--------------------------------------------------
-- COLUMN CONFIGURATION
--------------------------------------------------

local columnGap = 3

local columnWidth =
    math.floor(
        (width - columnGap) / 2
    )

local rightColumn =
    columnWidth + columnGap + 1


--------------------------------------------------
-- INITIALIZATION
--------------------------------------------------

if type(screen.setTextScale) ==
    "function" then

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
-- WRITE AT POSITION
--------------------------------------------------

local function writeAt(
    x,
    y,
    text,
    maxWidth
)

    if y < 1
        or y > height then

        return

    end


    local value =
        tostring(
            text or ""
        )


    local limit =
        maxWidth
        or
        (width - x + 1)


    if #value > limit then

        value =
            value:sub(
                1,
                limit
            )

    end


    screen.setCursorPos(
        x,
        y
    )


    screen.write(
        value
    )

end


--------------------------------------------------
-- WRITE LEFT COLUMN
--------------------------------------------------

local function left(
    row,
    text
)

    writeAt(
        1,
        row,
        text,
        columnWidth
    )

end


--------------------------------------------------
-- WRITE RIGHT COLUMN
--------------------------------------------------

local function right(
    row,
    text
)

    writeAt(
        rightColumn,
        row,
        text,
        columnWidth
    )

end


--------------------------------------------------
-- FULL WIDTH LINE
--------------------------------------------------

local function full(
    row,
    text
)

    writeAt(
        1,
        row,
        text,
        width
    )

end


--------------------------------------------------
-- NUMBER FORMAT
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
-- ANGLE FORMAT
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
-- STATUS
--------------------------------------------------

local function status(
    value
)

    if value == true then

        return "ON"

    end


    return "OFF"

end


--------------------------------------------------
-- HEADER
--------------------------------------------------

local function header(
    state,
    title
)

    full(
        1,
        "=== MISSILE CONTROL ==="
    )


    full(
        2,
        "MODE: " ..
        tostring(
            state.system.mode
        )
    )


    full(
        3,
        "[1]N [2]G [3]E [4]F [5]S"
    )


    full(
        4,
        "I=TGT S=START C=CTRL Q=OFF"
    )


    full(
        5,
        title
    )


    full(
        6,
        "--------------------------------"
    )

end


--------------------------------------------------
-- SAVE TARGET
--------------------------------------------------

local function saveTarget(
    state
)

    local file =
        fs.open(
            TARGET_FILE,
            "w"
        )


    if not file then

        return false

    end


    file.write(
        textutils.serialize(
            {
                x =
                    tonumber(
                        state.target.x
                    )
                    or
                    0,

                y =
                    tonumber(
                        state.target.y
                    )
                    or
                    0,

                z =
                    tonumber(
                        state.target.z
                    )
                    or
                    0,

                set =
                    state.target.set
                    == true,

                revision =
                    tonumber(
                        state.target.revision
                    )
                    or
                    0
            }
        )
    )


    file.close()


    return true

end


--------------------------------------------------
-- SAVE START
--------------------------------------------------

local function saveStart(
    state
)

    local file =
        fs.open(
            START_FILE,
            "w"
        )


    if not file then

        return false

    end


    file.write(
        textutils.serialize(
            {
                x =
                    tonumber(
                        state.startPosition.x
                    )
                    or
                    0,

                y =
                    tonumber(
                        state.startPosition.y
                    )
                    or
                    0,

                z =
                    tonumber(
                        state.startPosition.z
                    )
                    or
                    0,

                set =
                    state.startPosition.set
                    == true
            }
        )
    )


    file.close()


    return true

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


    if type(data) ~=
        "table" then

        return

    end


    state.startPosition.x =
        tonumber(
            data.x
        )
        or
        0


    state.startPosition.y =
        tonumber(
            data.y
        )
        or
        0


    state.startPosition.z =
        tonumber(
            data.z
        )
        or
        0


    state.startPosition.set =
        data.set == true

end


--------------------------------------------------
-- NAVIGATION PAGE
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
        state.navigation
        or {}


    local p =
        n.position
        or
        {
            x = 0,
            y = 0,
            z = 0
        }


    local v =
        n.velocity
        or
        {
            x = 0,
            y = 0,
            z = 0
        }


    --------------------------------------------------
    -- LEFT COLUMN
    --------------------------------------------------

    left(
        7,
        "STATUS " ..
        tostring(
            n.status
            or
            "OFFLINE"
        )
    )


    left(
        8,
        "X " ..
        fmt(p.x, 1)
    )


    left(
        9,
        "Y " ..
        fmt(p.y, 1)
    )


    left(
        10,
        "Z " ..
        fmt(p.z, 1)
    )


    left(
        11,
        "ALT " ..
        fmt(n.altitude, 1)
    )


    left(
        12,
        "V/S " ..
        fmt(n.verticalSpeed, 1)
    )


    left(
        13,
        "SPEED " ..
        fmt(n.speed, 2)
    )


    left(
        14,
        "VX " ..
        fmt(v.x, 2)
    )


    left(
        15,
        "VY " ..
        fmt(v.y, 2)
    )


    left(
        16,
        "VZ " ..
        fmt(v.z, 2)
    )


    left(
        17,
        "HDG " ..
        deg(n.heading)
    )


    left(
        18,
        "PITCH " ..
        deg(n.pitch)
    )


    left(
        19,
        "ROLL " ..
        deg(n.roll)
    )


    --------------------------------------------------
    -- RIGHT COLUMN
    --------------------------------------------------

    right(
        7,
        "ANG X " ..
        fmt(
            n.angularRateX,
            2
        )
    )


    right(
        8,
        "ANG Y " ..
        fmt(
            n.angularRateY,
            2
        )
    )


    right(
        9,
        "ANG Z " ..
        fmt(
            n.angularRateZ,
            2
        )
    )


    right(
        10,
        "DIST " ..
        fmt(
            n.distance,
            1
        )
    )


    right(
        11,
        "BRG " ..
        deg(
            n.bearing
        )
    )


    right(
        12,
        "ELV " ..
        deg(
            n.elevation
        )
    )


    right(
        13,
        "DXYZ"
    )


    right(
        14,
        "DX " ..
        fmt(
            n.targetDeltaX,
            1
        )
    )


    right(
        15,
        "DY " ..
        fmt(
            n.targetDeltaY,
            1
        )
    )


    right(
        16,
        "DZ " ..
        fmt(
            n.targetDeltaZ,
            1
        )
    )


    right(
        17,
        "TABLE " ..
        status(
            n.navigationTable
        )
    )


    right(
        18,
        "ALT " ..
        status(
            n.altitudeSensor
        )
    )


    right(
        19,
        "GIM " ..
        status(
            n.gimbalSensor
        )
    )


    right(
        20,
        "VEL " ..
        status(
            n.velocitySensor
        )
    )


    --------------------------------------------------
    -- BOTTOM
    --------------------------------------------------

    full(
        22,
        "NAV TARGET: " ..
        tostring(
            n.navigationTargetStatus
            or
            "UNKNOWN"
        )
    )


    full(
        23,
        "MANUAL TARGET: " ..
        (
            state.target.set
            and
            "SET"
            or
            "NONE"
        )
    )


    full(
        24,
        "I=TARGET"
    )

end


--------------------------------------------------
-- GUIDANCE PAGE
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
        state.guidance
        or {}


    local n =
        state.navigation
        or {}


    --------------------------------------------------
    -- LEFT
    --------------------------------------------------

    left(
        7,
        "STATUS " ..
        tostring(
            g.status
            or
            "OFFLINE"
        )
    )


    left(
        8,
        "ACTIVE " ..
        (
            g.active
            and
            "YES"
            or
            "NO"
        )
    )


    left(
        9,
        "CTRL " ..
        (
            state.system.controlEnabled
            and
            "ON"
            or
            "OFF"
        )
    )


    left(
        10,
        "PHASE " ..
        tostring(
            g.flightPhase
            or
            "READY"
        )
    )


    left(
        11,
        "TARGET " ..
        (
            state.target.set
            and
            "SET"
            or
            "NONE"
        )
    )


    left(
        12,
        "DIST " ..
        fmt(
            n.distance,
            1
        )
    )


    left(
        13,
        "YAW ERR " ..
        deg(
            g.yawError
        )
    )


    left(
        14,
        "PITCH ERR " ..
        deg(
            g.pitchError
        )
    )


    left(
        15,
        "YAW RATE " ..
        deg(
            g.yawRate
        )
    )


    left(
        16,
        "PITCH RATE " ..
        deg(
            g.pitchRate
        )
    )


    left(
        17,
        "YAW CMD " ..
        fmt(
            g.commandY,
            3
        )
    )


    left(
        18,
        "PITCH CMD " ..
        fmt(
            g.commandX,
            3
        )
    )


    --------------------------------------------------
    -- RIGHT
    --------------------------------------------------

    right(
        7,
        "YAW P " ..
        fmt(
            g.yawP,
            3
        )
    )


    right(
        8,
        "YAW I " ..
        fmt(
            g.yawI,
            4
        )
    )


    right(
        9,
        "YAW D " ..
        fmt(
            g.yawD,
            3
        )
    )


    right(
        10,
        "PITCH P " ..
        fmt(
            g.pitchP,
            3
        )
    )


    right(
        11,
        "PITCH I " ..
        fmt(
            g.pitchI,
            4
        )
    )


    right(
        12,
        "PITCH D " ..
        fmt(
            g.pitchD,
            3
        )
    )


    right(
        13,
        "T BRG " ..
        deg(
            g.targetBearing
        )
    )


    right(
        14,
        "T ELV " ..
        deg(
            g.targetElevation
        )
    )


    right(
        15,
        "MAX VEC " ..
        fmt(
            g.flightMaxVector,
            3
        )
    )


    right(
        16,
        "T DX " ..
        fmt(
            g.targetDX,
            1
        )
    )


    right(
        17,
        "T DY " ..
        fmt(
            g.targetDY,
            1
        )
    )


    right(
        18,
        "T DZ " ..
        fmt(
            g.targetDZ,
            1
        )
    )


    --------------------------------------------------
    -- BOTTOM
    --------------------------------------------------

    full(
        20,
        "NAV TABLE " ..
        status(
            n.navigationTable
        )
    )


    full(
        21,
        "GIMBAL " ..
        status(
            n.gimbalSensor
        )
    )


    full(
        22,
        "VELOCITY " ..
        status(
            n.velocitySensor
        )
    )


    full(
        23,
        "ALTITUDE " ..
        status(
            n.altitudeSensor
        )
    )


    full(
        24,
        "CONTROL C=ON/OFF"
    )

end


--------------------------------------------------
-- ENGINE PAGE
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
        state.thruster
        or {}


    local g =
        state.guidance
        or {}


    --------------------------------------------------
    -- LEFT
    --------------------------------------------------

    left(
        7,
        "ENGINES " ..
        tostring(
            t.engineCount
            or
            0
        )
    )


    left(
        8,
        "COMMAND " ..
        tostring(
            t.commandedEngines
            or
            0
        )
        ..
        "/" ..
        tostring(
            t.engineCount
            or
            0
        )
    )


    left(
        9,
        "STATUS " ..
        tostring(
            t.status
            or
            "OFFLINE"
        )
    )


    left(
        10,
        "CTRL " ..
        (
            state.system.controlEnabled
            and
            "ON"
            or
            "OFF"
        )
    )


    left(
        11,
        "CMD X " ..
        fmt(
            g.commandX,
            3
        )
    )


    left(
        12,
        "CMD Y " ..
        fmt(
            g.commandY,
            3
        )
    )


    left(
        13,
        "TARGET X " ..
        fmt(
            t.targetVectorX,
            3
        )
    )


    left(
        14,
        "TARGET Y " ..
        fmt(
            t.targetVectorY,
            3
        )
    )


    left(
        15,
        "ACTUAL X " ..
        fmt(
            t.vectorX,
            3
        )
    )


    left(
        16,
        "ACTUAL Y " ..
        fmt(
            t.vectorY,
            3
        )
    )


    left(
        17,
        "POWER " ..
        fmt(
            t.power,
            3
        )
    )


    left(
        18,
        "THRUST " ..
        fmt(
            t.thrust,
            3
        )
    )


    --------------------------------------------------
    -- RIGHT
    --------------------------------------------------

    local engines =
        t.engines
        or {}


    for i = 1,
        math.min(
            #engines,
            4
        ) do

        local entry =
            engines[i]


        local name =
            "---"


        if type(entry) ==
            "table" then

            name =
                tostring(
                    entry.name
                    or
                    "---"
                )

        else

            name =
                tostring(
                    entry
                    or
                    "---"
                )

        end


        right(
            7 + i - 1,
            "E" ..
            tostring(i) ..
            " " ..
            name
        )

    end


    right(
        12,
        "ERRORS " ..
        tostring(
            next(
                t.commandErrors
                or
                {}
            )
            and
            "YES"
            or
            "NO"
        )
    )


    right(
        13,
        "ONLINE " ..
        status(
            t.online
        )
    )


    right(
        14,
        "POWER " ..
        fmt(
            t.power,
            3
        )
    )


    right(
        15,
        "THRUST " ..
        fmt(
            t.thrust,
            3
        )
    )


    right(
        16,
        "VEC X " ..
        fmt(
            t.vectorX,
            3
        )
    )


    right(
        17,
        "VEC Y " ..
        fmt(
            t.vectorY,
            3
        )
    )


    --------------------------------------------------
    -- BOTTOM
    --------------------------------------------------

    full(
        20,
        "COMMAND SENT " ..
        tostring(
            t.commandedEngines
            or
            0
        ) ..
        "/" ..
        tostring(
            t.engineCount
            or
            0
        )
    )


    full(
        21,
        "TARGET VECTOR " ..
        fmt(
            t.targetVectorX,
            3
        ) ..
        " / " ..
        fmt(
            t.targetVectorY,
            3
        )
    )


    full(
        23,
        "ALL ENGINES CONTROLLED"
    )


    full(
        24,
        "C=CONTROL"
    )

end


--------------------------------------------------
-- FLIGHT PAGE
--------------------------------------------------

local function drawFlight(
    state
)

    clear()


    header(
        state,
        "FLIGHT SCENARIO"
    )


    local f =
        state.flight
        or {}


    local n =
        state.navigation
        or {}


    local g =
        state.guidance
        or {}


    --------------------------------------------------
    -- LEFT
    --------------------------------------------------

    left(
        7,
        "PHASE " ..
        tostring(
            f.phase
            or
            "READY"
        )
    )


    left(
        8,
        "STATUS " ..
        tostring(
            f.status
            or
            "READY"
        )
    )


    left(
        9,
        "FLIGHT " ..
        fmt(
            f.elapsed,
            1
        ) ..
        "s"
    )


    left(
        10,
        "PHASE " ..
        fmt(
            f.phaseElapsed,
            1
        ) ..
        "s"
    )


    left(
        11,
        "ALT " ..
        fmt(
            n.altitude,
            1
        )
    )


    left(
        12,
        "BOOST END " ..
        fmt(
            g.boostAltitude
            or
            100,
            0
        )
    )


    left(
        13,
        "CRUISE ALT " ..
        fmt(
            g.cruiseAltitude
            or
            300,
            0
        )
    )


    left(
        14,
        "SPEED " ..
        fmt(
            n.speed,
            2
        )
    )


    left(
        15,
        "VERT SPEED " ..
        fmt(
            n.verticalSpeed,
            2
        )
    )


    left(
        16,
        "DIST " ..
        fmt(
            n.distance,
            1
        )
    )


    left(
        17,
        "TERM DIST " ..
        fmt(
            g.terminalDistance
            or
            500,
            0
        )
    )


    --------------------------------------------------
    -- RIGHT
    --------------------------------------------------

    right(
        7,
        "BOOST " ..
        (
            f.boost
            and
            "YES"
            or
            "NO"
        )
    )


    right(
        8,
        "PITCH OVER " ..
        (
            f.pitchOver
            and
            "YES"
            or
            "NO"
        )
    )


    right(
        9,
        "CRUISE " ..
        (
            f.cruise
            and
            "YES"
            or
            "NO"
        )
    )


    right(
        10,
        "TERMINAL " ..
        (
            f.terminal
            and
            "YES"
            or
            "NO"
        )
    )


    right(
        11,
        "TARGET " ..
        (
            state.target.set
            and
            "SET"
            or
            "NONE"
        )
    )


    right(
        12,
        "CONTROL " ..
        (
            state.system.controlEnabled
            and
            "ON"
            or
            "OFF"
        )
    )


    right(
        13,
        "MAX VEC " ..
        fmt(
            g.flightMaxVector,
            3
        )
    )


    right(
        14,
        "YAW CMD " ..
        fmt(
            g.commandY,
            3
        )
    )


    right(
        15,
        "PITCH CMD " ..
        fmt(
            g.commandX,
            3
        )
    )


    right(
        16,
        "YAW ERR " ..
        deg(
            g.yawError
        )
    )


    right(
        17,
        "PITCH ERR " ..
        deg(
            g.pitchError
        )
    )


    right(
        18,
        "TARGET BRG " ..
        deg(
            g.targetBearing
        )
    )


    right(
        19,
        "TARGET ELV " ..
        deg(
            g.targetElevation
        )
    )


    full(
        21,
        "START " ..
        (
            state.startPosition.set
            and
            "SET"
            or
            "NONE"
        )
    )


    full(
        22,
        "TARGET " ..
        (
            state.target.set
            and
            "SET"
            or
            "NONE"
        )
    )


    full(
        23,
        "T XYZ " ..
        fmt(
            state.target.x,
            0
        ) ..
        " " ..
        fmt(
            state.target.y,
            0
        ) ..
        " " ..
        fmt(
            state.target.z,
            0
        )
    )


    full(
        24,
        "C=CONTROL"
    )

end


--------------------------------------------------
-- SYSTEM PAGE
--------------------------------------------------

local function drawSystem(
    state
)

    clear()


    header(
        state,
        "SYSTEM / DIAGNOSTICS"
    )


    local n =
        state.navigation
        or {}


    local g =
        state.guidance
        or {}


    local t =
        state.thruster
        or {}


    local f =
        state.flight
        or {}


    --------------------------------------------------
    -- LEFT
    --------------------------------------------------

    left(
        7,
        "SYS " ..
        tostring(
            state.system.status
        )
    )


    left(
        8,
        "CTRL " ..
        (
            state.system.controlEnabled
            and
            "ON"
            or
            "OFF"
        )
    )


    left(
        9,
        "FLIGHT " ..
        tostring(
            f.phase
            or
            "READY"
        )
    )


    left(
        10,
        "NAV " ..
        status(
            n.online
        )
    )


    left(
        11,
        "TABLE " ..
        status(
            n.navigationTable
        )
    )


    left(
        12,
        "NAV TGT " ..
        tostring(
            n.navigationTargetStatus
            or
            "UNKNOWN"
        )
    )


    left(
        13,
        "ALT " ..
        status(
            n.altitudeSensor
        )
    )


    left(
        14,
        "GIM " ..
        status(
            n.gimbalSensor
        )
    )


    left(
        15,
        "VEL " ..
        status(
            n.velocitySensor
        )
    )


    --------------------------------------------------
    -- RIGHT
    --------------------------------------------------

    right(
        7,
        "GUIDE " ..
        status(
            g.online
        )
    )


    right(
        8,
        "ACTIVE " ..
        (
            g.active
            and
            "YES"
            or
            "NO"
        )
    )


    right(
        9,
        "THR " ..
        status(
            t.online
        )
    )


    right(
        10,
        "ENG " ..
        tostring(
            t.engineCount
            or
            0
        )
    )


    right(
        11,
        "CMD " ..
        tostring(
            t.commandedEngines
            or
            0
        ) ..
        "/" ..
        tostring(
            t.engineCount
            or
            0
        )
    )


    right(
        12,
        "MANUAL TGT " ..
        (
            state.target.set
            and
            "SET"
            or
            "NONE"
        )
    )


    right(
        13,
        "DIST " ..
        fmt(
            n.distance,
            1
        )
    )


    right(
        14,
        "SPEED " ..
        fmt(
            n.speed,
            1
        )
    )


    right(
        15,
        "ALT " ..
        fmt(
            n.altitude,
            1
        )
    )


    right(
        16,
        "PHASE T " ..
        fmt(
            f.phaseElapsed,
            1
        )
    )


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    full(
        18,
        "TARGET X " ..
        fmt(
            state.target.x,
            0
        )
    )


    full(
        19,
        "TARGET Y " ..
        fmt(
            state.target.y,
            0
        )
    )


    full(
        20,
        "TARGET Z " ..
        fmt(
            state.target.z,
            0
        )
    )


    full(
        21,
        "START " ..
        (
            state.startPosition.set
            and
            "SET"
            or
            "NONE"
        )
    )


    full(
        22,
        "NAV SIGNALS " ..
        status(
            n.online
        )
    )


    full(
        23,
        "GUIDANCE " ..
        status(
            g.online
        )
    )


    full(
        24,
        "I TGT | S START | C CTRL"
    )

end


--------------------------------------------------
-- DRAW PAGE
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


    elseif page == 4 then

        drawFlight(
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


        full(
            1,
            "=== MISSILE CONTROL ==="
        )


        full(
            2,
            title
        )


        full(
            3,
            "--------------------------------"
        )


        full(
            5,
            "ENTER COORDINATES"
        )


        full(
            7,
            (
                active == 1
                and
                "> X: "
                or
                "  X: "
            ) ..
            values[1]
        )


        full(
            8,
            (
                active == 2
                and
                "> Y: "
                or
                "  Y: "
            ) ..
            values[2]
        )


        full(
            9,
            (
                active == 3
                and
                "> Z: "
                or
                "  Z: "
            ) ..
            values[3]
        )


        full(
            11,
            "ENTER = NEXT / SAVE"
        )


        full(
            12,
            "BACKSPACE = DELETE"
        )


        full(
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

                    full(
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
                        tonumber(
                            values[1]
                        ),
                        tonumber(
                            values[2]
                        ),
                        tonumber(
                            values[3]
                        )
                    )


                    return

                end


            elseif a ==
                keys.r then

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
-- SET TARGET
--------------------------------------------------

local function setTarget(
    state
)

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
                    )
                    or
                    0
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
-- SET START
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

    if key ==
        keys.one then

        page = 1


    elseif key ==
        keys.two then

        page = 2


    elseif key ==
        keys.three then

        page = 3


    elseif key ==
        keys.four then

        page = 4


    elseif key ==
        keys.five then

        page = 5


    elseif key ==
        keys.i then

        setTarget(
            state
        )


        return


    elseif key ==
        keys.s then

        setStart(
            state
        )


        return


    elseif key ==
        keys.c then

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


    elseif key ==
        keys.q then

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

    if type(state) ~=
        "table" then

        error(
            "DISPLAY: INVALID STATE"
        )

    end


    --------------------------------------------------
    -- ENSURE TARGET STATE
    --------------------------------------------------

    if type(
        state.target
    ) ~= "table" then

        state.target = {

            x = 0,
            y = 0,
            z = 0,

            set = false,

            revision = 0

        }

    end


    --------------------------------------------------
    -- ENSURE START STATE
    --------------------------------------------------

    if type(
        state.startPosition
    ) ~= "table" then

        state.startPosition = {

            x = 0,
            y = 0,
            z = 0,

            set = false

        }

    end


    state.display =
        state.display
        or {}


    state.display.online =
        true


    --------------------------------------------------
    -- LOAD START
    --------------------------------------------------

    loadStart(
        state
    )


    --------------------------------------------------
    -- INITIAL DRAW
    --------------------------------------------------

    draw(
        state
    )


    --------------------------------------------------
    -- MAIN LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do

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

            state.system.controlEnabled =
                false


            state.system.running =
                false

        end

    end


    --------------------------------------------------
    -- SAFETY
    --------------------------------------------------

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