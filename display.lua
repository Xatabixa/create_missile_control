-- Missile Control System Display
-- CC:Tweaked
--
-- Pages:
--   1 = Navigation
--   2 = Guidance
--   3 = Engine
--   4 = Flight
--   5 = System
--
-- Keys:
--   1-5 = pages
--   I   = target coordinates
--   S   = start position
--   C   = control
--   Q   = shutdown
--   R   = cancel coordinate input

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
-- BASIC DRAW FUNCTIONS
--------------------------------------------------

local function clear()

    screen.setBackgroundColor(colors.black)
    screen.setTextColor(colors.white)

    screen.clear()

    screen.setCursorPos(1, 1)

end


--------------------------------------------------
-- WRITE LINE
--------------------------------------------------

local function writeLine(
    row,
    text
)

    if row < 1 or row > height then
        return
    end

    local value =
        tostring(text or "")

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
        return "ONLINE"
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
        "[1]N [2]G [3]E [4]F [5]S"
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

    --------------------------------------------------
    -- POSITION
    --------------------------------------------------

    writeLine(
        7,
        "STATUS: " ..
        tostring(
            n.status
            or "OFFLINE"
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

    --------------------------------------------------
    -- MOTION
    --------------------------------------------------

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
        "VX " ..
        fmt(v.x, 2) ..
        " VY " ..
        fmt(v.y, 2)
    )

    writeLine(
        13,
        "VZ " ..
        fmt(v.z, 2)
    )

    --------------------------------------------------
    -- ATTITUDE
    --------------------------------------------------

    writeLine(
        14,
        "HDG " ..
        deg(n.heading)
    )

    writeLine(
        15,
        "PITCH " ..
        deg(n.pitch) ..
        " ROLL " ..
        deg(n.roll)
    )

    --------------------------------------------------
    -- ROTATION
    --------------------------------------------------

    writeLine(
        16,
        "ANG X " ..
        fmt(n.angularRateX, 2)
    )

    writeLine(
        17,
        "ANG Y " ..
        fmt(n.angularRateY, 2)
    )

    writeLine(
        18,
        "ANG Z " ..
        fmt(n.angularRateZ, 2)
    )

    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    writeLine(
        19,
        "DIST " ..
        fmt(n.distance, 1) ..
        " m"
    )

    writeLine(
        20,
        "BEARING " ..
        deg(n.bearing)
    )

    writeLine(
        21,
        "ELEVATION " ..
        deg(n.elevation)
    )

    --------------------------------------------------
    -- SIGNAL STATUS
    --------------------------------------------------

    writeLine(
        22,
        "NAV TABLE: " ..
        status(
            n.navigationTable
        )
    )

    writeLine(
        23,
        "ALT: " ..
        status(
            n.altitudeSensor
        ) ..
        " GIM: " ..
        status(
            n.gimbalSensor
        )
    )

    writeLine(
        24,
        "VEL: " ..
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
        state.guidance or {}

    local n =
        state.navigation or {}


    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    writeLine(
        7,
        "STATUS: " ..
        tostring(
            g.status
            or "OFFLINE"
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
        "PHASE: " ..
        tostring(
            g.flightPhase
            or
            state.flight
            and
            state.flight.phase
            or
            "READY"
        )
    )

    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    writeLine(
        11,
        "TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
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

    --------------------------------------------------
    -- ROTATION
    --------------------------------------------------

    writeLine(
        15,
        "YAW RATE: " ..
        deg(
            g.yawRate
        ) ..
        "/s"
    )

    writeLine(
        16,
        "PITCH RATE: " ..
        deg(
            g.pitchRate
        ) ..
        "/s"
    )

    --------------------------------------------------
    -- COMMAND
    --------------------------------------------------

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

    --------------------------------------------------
    -- PID
    --------------------------------------------------

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
    -- ENGINES
    --------------------------------------------------

    writeLine(
        7,
        "ENGINES: " ..
        tostring(
            t.engineCount
            or 0
        )
    )

    writeLine(
        8,
        "COMMAND: " ..
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

    writeLine(
        9,
        "STATUS: " ..
        tostring(
            t.status
            or "OFFLINE"
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

    --------------------------------------------------
    -- COMMAND
    --------------------------------------------------

    writeLine(
        11,
        "CMD X: " ..
        fmt(
            g.commandX,
            3
        )
    )

    writeLine(
        12,
        "CMD Y: " ..
        fmt(
            g.commandY,
            3
        )
    )

    --------------------------------------------------
    -- ENGINE VECTOR
    --------------------------------------------------

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

    --------------------------------------------------
    -- THRUST
    --------------------------------------------------

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
    -- ENGINE LIST
    --------------------------------------------------

    local engines =
        t.engines or {}


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
            "C=CONTROL"
        )

    end

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
        state.flight or {}

    local n =
        state.navigation or {}

    local g =
        state.guidance or {}


    --------------------------------------------------
    -- PHASE
    --------------------------------------------------

    writeLine(
        7,
        "PHASE: " ..
        tostring(
            f.phase
            or "READY"
        )
    )

    writeLine(
        8,
        "STATUS: " ..
        tostring(
            f.status
            or "READY"
        )
    )

    --------------------------------------------------
    -- TIME
    --------------------------------------------------

    writeLine(
        9,
        "FLIGHT TIME: " ..
        fmt(
            f.elapsed,
            1
        ) ..
        " s"
    )

    writeLine(
        10,
        "PHASE TIME: " ..
        fmt(
            f.phaseElapsed,
            1
        ) ..
        " s"
    )

    --------------------------------------------------
    -- ALTITUDE
    --------------------------------------------------

    writeLine(
        11,
        "ALTITUDE: " ..
        fmt(
            n.altitude,
            1
        ) ..
        " m"
    )

    writeLine(
        12,
        "BOOST END: " ..
        fmt(
            g.boostAltitude
            or
            100,
            0
        ) ..
        " m"
    )

    writeLine(
        13,
        "CRUISE ALT: " ..
        fmt(
            g.cruiseAltitude
            or
            300,
            0
        ) ..
        " m"
    )

    --------------------------------------------------
    -- VELOCITY
    --------------------------------------------------

    writeLine(
        14,
        "SPEED: " ..
        fmt(
            n.speed,
            2
        ) ..
        " m/s"
    )

    writeLine(
        15,
        "VERT SPEED: " ..
        fmt(
            n.verticalSpeed,
            2
        )
    )

    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    writeLine(
        16,
        "TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

    writeLine(
        17,
        "DISTANCE: " ..
        fmt(
            n.distance,
            1
        ) ..
        " m"
    )

    writeLine(
        18,
        "TERMINAL AT: " ..
        fmt(
            g.terminalDistance
            or
            500,
            0
        ) ..
        " m"
    )

    --------------------------------------------------
    -- FLAGS
    --------------------------------------------------

    writeLine(
        20,
        "BOOST: " ..
        (
            f.boost
            and "YES"
            or "NO"
        )
    )

    writeLine(
        21,
        "PITCH OVER: " ..
        (
            f.pitchOver
            and "YES"
            or "NO"
        )
    )

    writeLine(
        22,
        "CRUISE: " ..
        (
            f.cruise
            and "YES"
            or "NO"
        )
    )

    writeLine(
        23,
        "TERMINAL: " ..
        (
            f.terminal
            and "YES"
            or "NO"
        )
    )

    writeLine(
        24,
        "MAX VECTOR: " ..
        fmt(
            g.flightMaxVector,
            3
        )
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
        state.navigation or {}

    local g =
        state.guidance or {}

    local t =
        state.thruster or {}

    local f =
        state.flight or {}


    --------------------------------------------------
    -- CORE
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
        "CONTROL: " ..
        (
            state.system.controlEnabled
            and "ON"
            or "OFF"
        )
    )

    writeLine(
        9,
        "FLIGHT: " ..
        tostring(
            f.phase
            or "READY"
        )
    )

    --------------------------------------------------
    -- NAVIGATION
    --------------------------------------------------

    writeLine(
        11,
        "NAVIGATION: " ..
        status(
            n.online
        )
    )

    writeLine(
        12,
        "NAV TABLE: " ..
        status(
            n.navigationTable
        )
    )

    writeLine(
        13,
        "NAV TARGET: " ..
        tostring(
            n.navigationTargetStatus
            or "UNKNOWN"
        )
    )

    writeLine(
        14,
        "ALT SENSOR: " ..
        status(
            n.altitudeSensor
        )
    )

    writeLine(
        15,
        "GIMBAL: " ..
        status(
            n.gimbalSensor
        )
    )

    writeLine(
        16,
        "VELOCITY: " ..
        status(
            n.velocitySensor
        )
    )

    --------------------------------------------------
    -- GUIDANCE
    --------------------------------------------------

    writeLine(
        18,
        "GUIDANCE: " ..
        status(
            g.online
        )
    )

    writeLine(
        19,
        "GUIDE ACTIVE: " ..
        (
            g.active
            and "YES"
            or "NO"
        )
    )

    --------------------------------------------------
    -- ENGINE
    --------------------------------------------------

    writeLine(
        21,
        "THRUSTER: " ..
        status(
            t.online
        )
    )

    writeLine(
        22,
        "ENGINES: " ..
        tostring(
            t.engineCount
            or 0
        )
    )

    writeLine(
        23,
        "COMMAND: " ..
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

    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    writeLine(
        24,
        "MANUAL TARGET: " ..
        (
            state.target.set
            and "SET"
            or "NOT SET"
        )
    )

end


--------------------------------------------------
-- DRAW CURRENT PAGE
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


        --------------------------------------------------
        -- CHARACTER
        --------------------------------------------------

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


        --------------------------------------------------
        -- KEY
        --------------------------------------------------

        elseif event == "key" then


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


            --------------------------------------------------
            -- CANCEL
            --------------------------------------------------

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
-- TARGET INPUT
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
-- START POSITION INPUT
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
-- SAVE START
--------------------------------------------------

function saveStart(
    state
)

    local file =
        fs.open(
            START_FILE,
            "w"
        )


    if file then

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

end


--------------------------------------------------
-- KEY HANDLER
--------------------------------------------------

local function handleKey(
    state,
    key
)

    --------------------------------------------------
    -- PAGE 1
    --------------------------------------------------

    if key == keys.one then

        page = 1


    --------------------------------------------------
    -- PAGE 2
    --------------------------------------------------

    elseif key == keys.two then

        page = 2


    --------------------------------------------------
    -- PAGE 3
    --------------------------------------------------

    elseif key == keys.three then

        page = 3


    --------------------------------------------------
    -- PAGE 4
    --------------------------------------------------

    elseif key == keys.four then

        page = 4


    --------------------------------------------------
    -- PAGE 5
    --------------------------------------------------

    elseif key == keys.five then

        page = 5


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    elseif key == keys.i then

        setTarget(
            state
        )

        return


    --------------------------------------------------
    -- START
    --------------------------------------------------

    elseif key == keys.s then

        setStart(
            state
        )

        return


    --------------------------------------------------
    -- CONTROL
    --------------------------------------------------

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


    --------------------------------------------------
    -- SHUTDOWN
    --------------------------------------------------

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

    if type(state) ~=
        "table" then

        error(
            "DISPLAY: INVALID STATE"
        )

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


    state.display =
        state.display or {}


    state.display.online =
        true


    --------------------------------------------------
    -- LOAD SAVED START
    --------------------------------------------------

    loadStart(
        state
    )


    --------------------------------------------------
    -- FIRST DRAW
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
            "monitor_touch" then

            local x =
                a

            local _, _, y =
                os.pullEvent(
                    "monitor_touch"
                )


            if y >= height - 1 then

                local slot =
                    math.floor(
                        (
                            x - 1
                        ) *
                        5 /
                        math.max(
                            width,
                            1
                        )
                    ) + 1


                if slot < 1 then
                    slot = 1
                end


                if slot > 5 then
                    slot = 5
                end


                page =
                    slot


                draw(
                    state
                )

            end


        elseif event ==
            "terminate" then

            state.system.controlEnabled =
                false


            state.system.running =
                false

        end

    end


    --------------------------------------------------
    -- SAFETY SHUTDOWN
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