-- Guidance / State Diagnostic
-- CC:Tweaked
--
-- Reproduces the important part of launcher.lua:
--
--   state.lua
--      |
--      +--> target.lua
--      |
--      +--> navigation.lua
--      |
--      +--> this diagnostic
--
-- The diagnostic DOES NOT control engines.
--
-- CONTROLS:
--   UP / DOWN      scroll
--   PAGEUP/PAGEDOWN fast scroll
--   HOME / END     top / bottom
--   R               redraw / no reload
--   Q               exit
--
-- IMPORTANT:
-- This test does NOT call actuator.lua.
-- No thruster command is sent.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local REFRESH_TIME = 0.10


--------------------------------------------------
-- LOAD MODULE
--------------------------------------------------

local function loadModule(
    filename
)

    local chunk,
    errorText =
        loadfile(
            filename
        )

    if not chunk then

        error(
            "LOAD ERROR " ..
            filename ..
            ": " ..
            tostring(
                errorText
            )
        )

    end


    local ok,
    module =
        pcall(
            chunk
        )


    if not ok then

        error(
            "MODULE ERROR " ..
            filename ..
            ": " ..
            tostring(
                module
            )
        )

    end


    if type(module) ~= "table" then

        error(
            "INVALID MODULE " ..
            filename
        )

    end


    if type(module.run) ~= "function" then

        error(
            "NO RUN FUNCTION " ..
            filename
        )

    end


    return module

end


--------------------------------------------------
-- LOAD STATE
--------------------------------------------------

local stateChunk,
stateError =
    loadfile(
        "state.lua"
    )


if not stateChunk then

    error(
        "STATE LOAD ERROR: " ..
        tostring(
            stateError
        )
    )

end


local ok,
state =
    pcall(
        stateChunk
    )


if not ok then

    error(
        "STATE ERROR: " ..
        tostring(
            state
        )
    )

end


if type(state) ~= "table" then

    error(
        "STATE MODULE INVALID"
    )

end


--------------------------------------------------
-- LOAD ONLY TARGET + NAVIGATION
--------------------------------------------------

local target =
    loadModule(
        "target.lua"
    )


local navigation =
    loadModule(
        "navigation.lua"
    )


--------------------------------------------------
-- SYSTEM STATE
--------------------------------------------------

state.system.running =
    true

state.system.mode =
    "DIAGNOSTIC"

state.system.status =
    "DIAGNOSTIC"

state.system.controlEnabled =
    false

state.system.error =
    nil


--------------------------------------------------
-- TEXT BUFFER
--------------------------------------------------

local lines = {}

local scroll = 0


--------------------------------------------------
-- ADD LINE
--------------------------------------------------

local function add(
    text
)

    lines[#lines + 1] =
        tostring(
            text or ""
        )

end


--------------------------------------------------
-- FORMAT NUMBER
--------------------------------------------------

local function number(
    value,
    digits
)

    value =
        tonumber(
            value
        )


    if not value then

        return "---"

    end


    return string.format(
        "%." ..
        tostring(
            digits or 3
        ) ..
        "f",
        value
    )

end


--------------------------------------------------
-- ANGLE
--------------------------------------------------

local function angle(
    value
)

    value =
        tonumber(
            value
        )


    if not value then

        return "---"

    end


    return string.format(
        "%.3f°",
        math.deg(
            value
        )
    )

end


--------------------------------------------------
-- BOOLEAN
--------------------------------------------------

local function bool(
    value
)

    if value == true then

        return "TRUE"

    end


    if value == false then

        return "FALSE"

    end


    return "NIL"

end


--------------------------------------------------
-- TABLE VALUE
--------------------------------------------------

local function tableValue(
    value
)

    if type(value) ~=
        "table" then

        return "NOT TABLE"

    end


    local result =
        {}


    for key, item in pairs(
        value
    ) do

        local itemText


        if type(item) ==
            "table" then

            itemText =
                textutils.serialize(
                    item
                )

        else

            itemText =
                tostring(
                    item
                )

        end


        result[#result + 1] =
            tostring(key) ..
            "=" ..
            itemText

    end


    table.sort(
        result
    )


    return table.concat(
        result,
        " "
    )

end


--------------------------------------------------
-- BUILD REPORT
--------------------------------------------------

local function buildReport()

    lines =
        {}


    --------------------------------------------------
    -- HEADER
    --------------------------------------------------

    add(
        "=== GUIDANCE DIAGNOSTIC ==="
    )

    add(
        "Refresh: " ..
        tostring(
            REFRESH_TIME
        ) ..
        " s"
    )

    add("")


    --------------------------------------------------
    -- SYSTEM
    --------------------------------------------------

    add(
        "[SYSTEM]"
    )

    add(
        "running = " ..
        bool(
            state.system.running
        )
    )

    add(
        "mode = " ..
        tostring(
            state.system.mode
        )
    )

    add(
        "status = " ..
        tostring(
            state.system.status
        )
    )

    add(
        "control = " ..
        bool(
            state.system.controlEnabled
        )
    )

    add("")


    --------------------------------------------------
    -- TARGET
    --------------------------------------------------

    add(
        "[STATE.TARGET]"
    )


    local targetState =
        state.target
        or {}


    add(
        "table = " ..
        bool(
            state.target ~= nil
        )
    )


    add(
        "set = " ..
        bool(
            targetState.set
        )
    )


    add(
        "x = " ..
        number(
            targetState.x,
            3
        )
    )


    add(
        "y = " ..
        number(
            targetState.y,
            3
        )
    )


    add(
        "z = " ..
        number(
            targetState.z,
            3
        )
    )


    add(
        "revision = " ..
        tostring(
            targetState.revision
            or
            "---"
        )
    )


    add("")


    --------------------------------------------------
    -- NAVIGATION
    --------------------------------------------------

    add(
        "[NAVIGATION]"
    )


    local n =
        state.navigation
        or {}


    add(
        "status = " ..
        tostring(
            n.status
            or
            "---"
        )
    )


    add(
        "online = " ..
        bool(
            n.online
        )
    )


    add(
        "navigationTable = " ..
        bool(
            n.navigationTable
        )
    )


    add(
        "altitudeSensor = " ..
        bool(
            n.altitudeSensor
        )
    )


    add(
        "gimbalSensor = " ..
        bool(
            n.gimbalSensor
        )
    )


    add(
        "velocitySensor = " ..
        bool(
            n.velocitySensor
        )
    )


    add(
        "positionValid = " ..
        bool(
            n.positionValid
        )
    )


    add("")


    --------------------------------------------------
    -- POSITION
    --------------------------------------------------

    add(
        "[POSITION]"
    )


    local p =
        n.position
        or {}


    add(
        "X = " ..
        number(
            p.x,
            3
        )
    )


    add(
        "Y = " ..
        number(
            p.y,
            3
        )
    )


    add(
        "Z = " ..
        number(
            p.z,
            3
        )
    )


    add(
        "startAltitude = " ..
        number(
            n.startAltitude,
            3
        )
    )


    add("")


    --------------------------------------------------
    -- TARGET VECTOR
    --------------------------------------------------

    add(
        "[TARGET VECTOR]"
    )


    add(
        "targetDeltaX = " ..
        number(
            n.targetDeltaX,
            3
        )
    )


    add(
        "targetDeltaY = " ..
        number(
            n.targetDeltaY,
            3
        )
    )


    add(
        "targetDeltaZ = " ..
        number(
            n.targetDeltaZ,
            3
        )
    )


    add(
        "targetDistance = " ..
        number(
            n.targetDistance,
            3
        )
    )


    add(
        "hasNavTarget = " ..
        bool(
            n.hasNavTarget
        )
    )


    add("")


    --------------------------------------------------
    -- LOCAL TARGET
    --------------------------------------------------

    add(
        "[LOCAL TARGET]"
    )


    add(
        "X = " ..
        number(
            n.localTargetX,
            6
        )
    )


    add(
        "Y = " ..
        number(
            n.localTargetY,
            6
        )
    )


    add(
        "Z = " ..
        number(
            n.localTargetZ,
            6
        )
    )


    add(
        "targetYaw = " ..
        angle(
            n.targetYaw
        )
    )


    add(
        "targetPitch = " ..
        angle(
            n.targetPitch
        )
    )


    add("")


    --------------------------------------------------
    -- ORIENTATION
    --------------------------------------------------

    add(
        "[ORIENTATION]"
    )


    local q =
        n.orientation
        or {}


    add(
        "quat X = " ..
        number(
            q.x,
            9
        )
    )


    add(
        "quat Y = " ..
        number(
            q.y,
            9
        )
    )


    add(
        "quat Z = " ..
        number(
            q.z,
            9
        )
    )


    add(
        "quat W = " ..
        number(
            q.w,
            9
        )
    )


    add(
        "heading = " ..
        angle(
            n.heading
        )
    )


    add(
        "pitch = " ..
        angle(
            n.pitch
        )
    )


    add(
        "roll = " ..
        angle(
            n.roll
        )
    )


    add("")


    --------------------------------------------------
    -- FORWARD VECTOR
    --------------------------------------------------

    add(
        "[FORWARD VECTOR]"
    )


    local f =
        n.forward
        or {}


    add(
        "X = " ..
        number(
            f.x,
            6
        )
    )


    add(
        "Y = " ..
        number(
            f.y,
            6
        )
    )


    add(
        "Z = " ..
        number(
            f.z,
            6
        )
    )


    add("")


    --------------------------------------------------
    -- ANGULAR RATE
    --------------------------------------------------

    add(
        "[ANGULAR RATE]"
    )


    add(
        "X = " ..
        number(
            n.angularRateX,
            6
        )
    )


    add(
        "Y = " ..
        number(
            n.angularRateY,
            6
        )
    )


    add(
        "Z = " ..
        number(
            n.angularRateZ,
            6
        )
    )


    add("")


    --------------------------------------------------
    -- VELOCITY
    --------------------------------------------------

    add(
        "[VELOCITY]"
    )


    local v =
        n.velocity
        or {}


    local bv =
        n.bodyVelocity
        or {}


    add(
        "body X = " ..
        number(
            bv.x,
            6
        )
    )


    add(
        "body Y = " ..
        number(
            bv.y,
            6
        )
    )


    add(
        "body Z = " ..
        number(
            bv.z,
            6
        )
    )


    add(
        "world X = " ..
        number(
            v.x,
            6
        )
    )


    add(
        "world Y = " ..
        number(
            v.y,
            6
        )
    )


    add(
        "world Z = " ..
        number(
            v.z,
            6
        )
    )


    add(
        "speed = " ..
        number(
            n.speed,
            6
        )
    )


    add("")


    --------------------------------------------------
    -- ALTITUDE
    --------------------------------------------------

    add(
        "[ALTITUDE]"
    )


    add(
        "altitude = " ..
        number(
            n.altitude,
            6
        )
    )


    add(
        "verticalSpeed = " ..
        number(
            n.verticalSpeed,
            6
        )
    )


    add(
        "airPressure = " ..
        number(
            n.airPressure,
            6
        )
    )


    add("")


    --------------------------------------------------
    -- INTERNAL NAV TABLE TARGET
    --------------------------------------------------

    add(
        "[NAV TABLE TARGET]"
    )


    add(
        "hasTarget = " ..
        bool(
            n.navigationTarget
        )
    )


    add(
        "status = " ..
        tostring(
            n.navigationTargetStatus
            or
            "---"
        )
    )


    add(
        "bearing = " ..
        angle(
            n.bearing
        )
    )


    add(
        "relativeAngle = " ..
        angle(
            n.relativeAngle
        )
    )


    add(
        "distance = " ..
        number(
            n.navTableDistance,
            3
        )
    )


    add(
        "elevation = " ..
        angle(
            n.elevation
        )
    )


    add(
        "closureRate = " ..
        number(
            n.closureRate,
            6
        )
    )


    add("")


    --------------------------------------------------
    -- START POSITION
    --------------------------------------------------

    add(
        "[START POSITION]"
    )


    local start =
        state.startPosition
        or {}


    add(
        "set = " ..
        bool(
            start.set
        )
    )


    add(
        "X = " ..
        number(
            start.x,
            3
        )
    )


    add(
        "Y = " ..
        number(
            start.y,
            3
        )
    )


    add(
        "Z = " ..
        number(
            start.z,
            3
        )
    )


    add("")


    --------------------------------------------------
    -- RAW NAVIGATION TABLE ORIENTATION
    --------------------------------------------------

    add(
        "[RAW DIAGNOSTIC]"
    )


    add(
        "orientation table:"
    )


    add(
        tableValue(
            n.orientation
            or
            {}
        )
    )


    add("")


    --------------------------------------------------
    -- END
    --------------------------------------------------

    add(
        "=============================="
    )


    add(
        "END OF REPORT"
    )


    add("")


    add(
        "UP/DOWN = SCROLL"
    )


    add(
        "PAGEUP/PAGEDOWN = FAST"
    )


    add(
        "HOME/END = TOP/BOTTOM"
    )


    add(
        "Q = EXIT"
    )

end


--------------------------------------------------
-- DRAW
--------------------------------------------------

local function draw()

    term.clear()

    term.setCursorPos(
        1,
        1
    )


    local termWidth,
    termHeight =
        term.getSize()


    local visible =
        termHeight - 1


    local maximum =
        math.max(
            0,
            #lines -
            visible
        )


    if scroll < 0 then
        scroll = 0
    end


    if scroll > maximum then
        scroll = maximum
    end


    term.write(
        "DIAGNOSTIC "
        ..
        tostring(scroll)
        ..
        "/"
        ..
        tostring(maximum)
    )


    for row = 2,
        termHeight do

        local index =
            scroll +
            row -
            1


        term.setCursorPos(
            1,
            row
        )


        term.clearLine()


        local text =
            lines[index]


        if text then

            if #text > termWidth then

                text =
                    text:sub(
                        1,
                        termWidth
                    )

            end


            term.write(
                text
            )

        end

    end

end


--------------------------------------------------
-- NAVIGATION PROCESS
--------------------------------------------------

local function navigationProcess()

    local success,
    errorText =
        pcall(
            navigation.run,
            state
        )


    if not success then

        state.system.error =
            "NAVIGATION: " ..
            tostring(
                errorText
            )


        state.system.running =
            false

    end

end


--------------------------------------------------
-- TARGET PROCESS
--------------------------------------------------

local function targetProcess()

    local success,
    errorText =
        pcall(
            target.run,
            state
        )


    if not success then

        state.system.error =
            "TARGET: " ..
            tostring(
                errorText
            )


        state.system.running =
            false

    end

end


--------------------------------------------------
-- REFRESH PROCESS
--------------------------------------------------

local function refreshProcess()

    while state.system.running do

        buildReport()

        draw()

        sleep(
            REFRESH_TIME
        )

    end

end


--------------------------------------------------
-- INPUT PROCESS
--------------------------------------------------

local function inputProcess()

    while state.system.running do

        local event,
        key =
            os.pullEventRaw()


        if event ==
            "key" then


            --------------------------------------------------
            -- UP
            --------------------------------------------------

            if key ==
                keys.up then

                scroll =
                    scroll -
                    1


                draw()


            --------------------------------------------------
            -- DOWN
            --------------------------------------------------

            elseif key ==
                keys.down then

                scroll =
                    scroll +
                    1


                draw()


            --------------------------------------------------
            -- PAGE UP
            --------------------------------------------------

            elseif key ==
                keys.pageUp then

                local _, h =
                    term.getSize()


                scroll =
                    scroll -
                    math.max(
                        1,
                        h - 2
                    )


                draw()


            --------------------------------------------------
            -- PAGE DOWN
            --------------------------------------------------

            elseif key ==
                keys.pageDown then

                local _, h =
                    term.getSize()


                scroll =
                    scroll +
                    math.max(
                        1,
                        h - 2
                    )


                draw()


            --------------------------------------------------
            -- HOME
            --------------------------------------------------

            elseif key ==
                keys.home then

                scroll =
                    0


                draw()


            --------------------------------------------------
            -- END
            --------------------------------------------------

            elseif key ==
                keys["end"] then

                scroll =
                    #lines


                draw()


            --------------------------------------------------
            -- REFRESH
            --------------------------------------------------

            elseif key ==
                keys.r then

                buildReport()

                draw()


            --------------------------------------------------
            -- EXIT
            --------------------------------------------------

            elseif key ==
                keys.q then

                state.system.running =
                    false

            end

        elseif event ==
            "terminate" then

            state.system.running =
                false

        end

    end

end


--------------------------------------------------
-- INITIAL REPORT
--------------------------------------------------

buildReport()

draw()


--------------------------------------------------
-- RUN
--------------------------------------------------

parallel.waitForAll(

    navigationProcess,

    targetProcess,

    refreshProcess,

    inputProcess

)


--------------------------------------------------
-- EXIT
--------------------------------------------------

state.system.running =
    false


term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "GUIDANCE DIAGNOSTIC STOPPED"
)