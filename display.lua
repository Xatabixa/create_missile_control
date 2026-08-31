-- Missile Control System Display
-- CC:Tweaked
--
-- 5 pages
-- Two-column interface
-- Real-time display refresh
--
-- 1 = Navigation
-- 2 = Guidance
-- 3 = Engine
-- 4 = Flight
-- 5 = System
--
-- I = target
-- S = start
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

local TARGET_FILE =
    "target.cfg"

local START_FILE =
    "start.cfg"


--------------------------------------------------
-- COLUMNS
--------------------------------------------------

local columnGap = 3


local columnWidth =
    math.floor(
        (width - columnGap) / 2
    )


local rightColumn =
    columnWidth +
    columnGap +
    1


--------------------------------------------------
-- REFRESH
--------------------------------------------------

local REFRESH_TIME =
    0.10


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

local function writeAt(
    x,
    y,
    text,
    maxWidth
)

    if y < 1
        or
        y > height then

        return
    end


    local value =
        tostring(
            text or ""
        )


    local limit =
        maxWidth
        or
        width - x + 1


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
-- LEFT
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
-- RIGHT
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
-- FULL
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
-- NUMBER
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
-- DEGREES
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
                    ) or 0,

                y =
                    tonumber(
                        state.target.y
                    ) or 0,

                z =
                    tonumber(
                        state.target.z
                    ) or 0,

                set =
                    state.target.set
                    == true,

                revision =
                    tonumber(
                        state.target.revision
                    ) or 0
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
        {}


    local v =
        n.velocity
        or
        {}


    --------------------------------------------------
    -- LEFT
    --------------------------------------------------

    left(
        7,
        "STATUS " ..
        tostring(
            n.status
            or
            "OFF"
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
        "HDG " ..
        deg(n.heading)
    )


    left(
        15,
        "PITCH " ..
        deg(n.pitch)
    )


    left(
        16,
        "ROLL " ..
        deg(n.roll)
    )


    left(
        17,
        "VX " ..
        fmt(v.x, 2)
    )


    left(
        18,
        "VY " ..
        fmt(v.y, 2)
    )


    left(
        19,
        "VZ " ..
        fmt(v.z, 2)
    )


    left(
        20,
        "ANG X " ..
        fmt(n.angularRateX, 2)
    )


    left(
        21,
        "ANG Y " ..
        fmt(n.angularRateY, 2)
    )


    left(
        22,
        "ANG Z " ..
        fmt(n.angularRateZ, 2)
    )


    --------------------------------------------------
    -- RIGHT
    --------------------------------------------------

    right(
        7,
        "DIST " ..
        fmt(
            n.distance,
            1
        )
    )


    right(
        8,
        "BRG " ..
        deg(
            n.bearing
        )
    )


    right(
        9,
        "ELV " ..
        deg(
            n.elevation
        )
    )


    right(
        10,
        "TGT DX " ..
        fmt(
            n.targetDeltaX,
            1
        )
    )


    right(
        11,
        "TGT DY " ..
        fmt(
            n.targetDeltaY,
            1
        )
    )


    right(
        12,
        "TGT DZ " ..
        fmt(
            n.targetDeltaZ,
            1
        )
    )


    right(
        13,
        "LOCAL X " ..
        fmt(
            n.localTargetX,
            3
        )
    )


    right(
        14,
        "LOCAL Y " ..
        fmt(
            n.localTargetY,
            3
        )
    )


    right(
        15,
        "LOCAL Z " ..
        fmt(
            n.localTargetZ,
            3
        )
    )


    right(
        16,
        "T YAW " ..
        deg(
            n.targetYaw
        )
    )


    right(
        17,
        "T PITCH " ..
        deg(
            n.targetPitch
        )
    )


    right(
        18,
        "FWD X " ..
        fmt(
            n.forward
            and
            n.forward.x,
            3
        )
    )


    right(
        19,
        "FWD Y " ..
        fmt(
            n.forward
            and
            n.forward.y,
            3
        )
    )


    right(
        20,
        "FWD Z " ..
        fmt(
            n.forward
            and
            n.forward.z,
            3
        )
    )


    right(
        21,
        "TABLE " ..
        status(
            n.navigationTable
        )
    )


    right(
        22,
        "NAV TGT " ..
        tostring(
            n.navigationTargetStatus
            or
            "UNKNOWN"
        )
    )


    right(
        23,
        "ALT " ..
        status(
            n.altitudeSensor
        )
    )


    right(
        24,
        "GIM " ..
        status(
            n.gimbalSensor
        ) ..
        " VEL " ..
        status(
            n.velocitySensor
        )
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


    left(
        7,
        "STATUS " ..
        tostring(
            g.status
            or
            "OFF"
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
        "DIST " ..
        fmt(
            n.distance,
            1
        )
    )


    left(
        12,
        "YAW ERR " ..
        deg(
            g.yawError
        )
    )


    left(
        13,
        "PITCH ERR " ..
        deg(
            g.pitchError
        )
    )


    left(
        14,
        "YAW RATE " ..
        deg(
            g.yawRate
        )
    )


    left(
        15,
        "PITCH RATE " ..
        deg(
            g.pitchRate
        )
    )


    left(
        16,
        "YAW CMD " ..
        fmt(
            g.commandY,
            3
        )
    )


    left(
        17,
        "PITCH CMD " ..
        fmt(
            g.commandX,
            3
        )
    )


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
        "T YAW " ..
        deg(
            g.targetBearing
        )
    )


    right(
        14,
        "T PITCH " ..
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


    right(
        20,
        "TABLE " ..
        status(
            n.navigationTable
        )
    )


    right(
        21,
        "GIM " ..
        status(
            n.gimbalSensor
        )
    )


    right(
        22,
        "ALT " ..
        status(
            n.altitudeSensor
        )
    )


    right(
        23,
        "VEL " ..
        status(
            n.velocitySensor
        )
    )


    right(
        24,
        "C=CONTROL"
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
    -- LEFT COLUMN
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
        ) ..
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
            "OFF"
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


    --------------------------------------------------
    -- REQUESTED VECTOR
    --------------------------------------------------

    left(
        11,
        "REQ X " ..
        fmt(
            t.requestedVectorX,
            3
        )
    )


    left(
        12,
        "REQ Y " ..
        fmt(
            t.requestedVectorY,
            3
        )
    )


    --------------------------------------------------
    -- APPLIED VECTOR
    --------------------------------------------------

    left(
        13,
        "OUT X " ..
        fmt(
            t.appliedVectorX,
            3
        )
    )


    left(
        14,
        "OUT Y " ..
        fmt(
            t.appliedVectorY,
            3
        )
    )


    --------------------------------------------------
    -- ACTUAL ENGINE VECTOR
    --------------------------------------------------

    left(
        15,
        "ACT X " ..
        fmt(
            t.vectorX,
            3
        )
    )


    left(
        16,
        "ACT Y " ..
        fmt(
            t.vectorY,
            3
        )
    )


    --------------------------------------------------
    -- POWER / THRUST
    --------------------------------------------------

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
    -- RIGHT COLUMN
    --------------------------------------------------

    local engines =
        t.engines
        or {}


    for i = 1,
        math.min(
            #engines,
            8
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


    --------------------------------------------------
    -- ENGINE STATUS
    --------------------------------------------------

    right(
        16,
        "ONLINE " ..
        status(
            t.online
        )
    )


    right(
        17,
        "ERROR " ..
        (
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
        18,
        "LIMIT " ..
        fmt(
            g.flightMaxVector,
            3
        )
    )


    --------------------------------------------------
    -- FULL WIDTH DIAGNOSTICS
    --------------------------------------------------

    full(
        20,
        "REQ " ..
        fmt(
            t.requestedVectorX,
            3
        ) ..
        " / " ..
        fmt(
            t.requestedVectorY,
            3
        )
    )


    full(
        21,
        "OUT " ..
        fmt(
            t.appliedVectorX,
            3
        ) ..
        " / " ..
        fmt(
            t.appliedVectorY,
            3
        )
    )


    full(
        22,
        "ACT " ..
        fmt(
            t.vectorX,
            3
        ) ..
        " / " ..
        fmt(
            t.vectorY,
            3
        )
    )


    full(
        23,
        "COMMAND " ..
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
        "PHASE T " ..
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
            g.boostAltitude,
            0
        )
    )


    left(
        13,
        "CRUISE ALT " ..
        fmt(
            g.cruiseAltitude,
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
        "VERT " ..
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
        "TERM " ..
        fmt(
            g.terminalDistance,
            0
        )
    )


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
        12,
        "VECTOR " ..
        fmt(
            g.flightMaxVector,
            3
        )
    )


    right(
        13,
        "YAW CMD " ..
        fmt(
            g.commandY,
            3
        )
    )


    right(
        14,
        "PITCH CMD " ..
        fmt(
            g.commandX,
            3
        )
    )


    right(
        15,
        "YAW ERR " ..
        deg(
            g.yawError
        )
    )


    right(
        16,
        "PITCH ERR " ..
        deg(
            g.pitchError
        )
    )


    right(
        17,
        "T YAW " ..
        deg(
            g.targetBearing
        )
    )


    right(
        18,
        "T PITCH " ..
        deg(
            g.targetElevation
        )
    )


    full(
        20,
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
        21,
        "XYZ " ..
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
        22,
        "NAV TABLE " ..
        status(
            n.navigationTable
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
        "FLT " ..
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
        "ALT " ..
        fmt(
            n.altitude,
            1
        )
    )


    right(
        15,
        "SPEED " ..
        fmt(
            n.speed,
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
        "ENGINES " ..
        tostring(
            t.engineCount
            or
            0
        )
    )


    full(
        22,
        "COMMAND " ..
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
        23,
        "NAV UPDATE " ..
        fmt(
            n.lastUpdate,
            2
        )
    )


    full(
        24,
        "REALTIME 0.10s"
    )

end


--------------------------------------------------
-- DRAW PAGE
--------------------------------------------------

local function draw(
    state
)

    state.display.page =
        page


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
-- TARGET
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
-- START
--------------------------------------------------

local function setStart(
    state
)

    local values = {
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
            "START POSITION"
        )


        full(
            3,
            "--------------------------------"
        )


        full(
            5,
            "ENTER X / Z"
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
                "> Z: "
                or
                "  Z: "
            ) ..
            values[2]
        )


        full(
            10,
            "Y = ALTITUDE SENSOR"
        )


        full(
            12,
            "ENTER = NEXT / SAVE"
        )


        full(
            13,
            "BACKSPACE = DELETE"
        )


        full(
            14,
            "R = CANCEL"
        )

    end


    redraw()


    while true do

        local event,
            a =
            os.pullEventRaw()


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
                        16,
                        "INVALID COORDINATE"
                    )


                    sleep(
                        0.8
                    )


                    redraw()


                elseif active < 2 then

                    active =
                        active + 1


                    redraw()


                else

                    state.startPosition.x =
                        tonumber(
                            values[1]
                        )


                    state.startPosition.z =
                        tonumber(
                            values[2]
                        )


                    state.startPosition.set =
                        true


                    --------------------------------------------------
                    -- Y is deliberately NOT written.
                    --------------------------------------------------

                    saveStart(
                        state
                    )


                    draw(
                        state
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

    --------------------------------------------------
    -- CONTROL
    --
    -- Before flight:
    --   C arms/enables control.
    --
    -- During flight:
    --   control stays latched ON.
    --
    -- Q remains the emergency shutdown.
    --------------------------------------------------

    if state.flight
        and
        state.flight.active then

        state.system.controlEnabled =
            true

        state.system.status =
            "CONTROL LOCKED"

    else

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


    loadStart(
        state
    )


    --------------------------------------------------
    -- REAL-TIME TIMER
    --------------------------------------------------

    local timer =
        os.startTimer(
            REFRESH_TIME
        )


    draw(
        state
    )


    --------------------------------------------------
    -- LOOP
    --------------------------------------------------

    while state.system
        and
        state.system.running do


        local event,
        a =
            os.pullEventRaw()


        --------------------------------------------------
        -- KEY
        --------------------------------------------------

        if event ==
            "key" then

            handleKey(
                state,
                a
            )


        --------------------------------------------------
        -- REAL-TIME REFRESH
        --------------------------------------------------

        elseif event ==
            "timer"
            and
            a == timer then

            draw(
                state
            )


            timer =
                os.startTimer(
                    REFRESH_TIME
                )


        --------------------------------------------------
        -- SHUTDOWN
        --------------------------------------------------

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