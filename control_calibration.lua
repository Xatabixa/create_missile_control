-- Missile Control Axis Calibration
-- CC:Tweaked
--
-- Purpose:
--   Determine how vector commands affect the
--   physical rotation of the rocket.
--
-- Real APIs:
--
-- Liquid Vector Thruster:
--   setVector()
--   setPowerNormalized()
--   getVectorX()
--   getVectorY()
--
-- Gimbal Sensor:
--   getAnglesRad()
--   getAngularRatesRad()
--
-- IMPORTANT:
--   DO NOT run launcher.lua at the same time.
--   actuator.lua must NOT be running.
--
-- IMPORTANT:
--   Rocket must be UNFROZEN during the pulse.
--
-- TEST:
--   +X
--   -X
--   +Y
--   -Y
--
-- Each test:
--   1. sets vector
--   2. starts low thrust
--   3. waits for the pulse
--   4. immediately stops thrust
--   5. reads Gimbal Sensor
--
-- CONTROLS:
--   SPACE     = start calibration
--   UP/DOWN   = scroll results
--   PAGEUP    = fast scroll up
--   PAGEDOWN  = fast scroll down
--   HOME      = top
--   END       = bottom
--   R         = redraw
--   Q         = quit
--
-- Every final state is forced to:
--   vector = 0,0
--   power  = 0

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local TEST_POWER = 0.03

local PULSE_TIME = 0.80

local SETTLE_TIME = 0.70

local BETWEEN_TESTS = 1.00


--------------------------------------------------
-- STATE
--------------------------------------------------

local thrusters = {}

local gimbal = nil

local results = {}

local reportLines = {}

local scroll = 0

local mode = "START"

local running = true


--------------------------------------------------
-- SAFE CALL
--------------------------------------------------

local function safeCall(
    device,
    method,
    ...
)

    if not device then

        return false, nil

    end


    local fn =
        device[method]


    if type(fn) ~= "function" then

        return false, nil

    end


    local ok,
        a,
        b,
        c,
        d =
        pcall(
            fn,
            ...
        )


    if not ok then

        return false, nil

    end


    return true,
        a,
        b,
        c,
        d

end


--------------------------------------------------
-- FIND THRUSTERS
--------------------------------------------------

local function scanThrusters()

    thrusters = {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        local methods =
            peripheral.getMethods(
                name
            )


        if type(methods) ==
            "table" then

            local hasVector =
                false


            local hasPower =
                false


            for _, method in ipairs(
                methods
            ) do

                if method ==
                    "setVector" then

                    hasVector =
                        true

                elseif method ==
                    "setPowerNormalized" then

                    hasPower =
                        true

                end

            end


            if hasVector
                and
                hasPower then

                local device =
                    peripheral.wrap(
                        name
                    )


                if device then

                    table.insert(
                        thrusters,
                        {
                            name = name,
                            device = device
                        }
                    )

                end

            end

        end

    end

end


--------------------------------------------------
-- FIND GIMBAL
--------------------------------------------------

local function scanGimbal()

    gimbal = nil


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            "gimbal_sensor"
        ) then

            local device =
                peripheral.wrap(
                    name
                )


            if device then

                gimbal = device

                return

            end

        end

    end

end


--------------------------------------------------
-- FORMAT
--------------------------------------------------

local function fmt(
    value
)

    value =
        tonumber(value)


    if not value then

        return "---"

    end


    return string.format(
        "%.6f",
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


    return string.format(
        "%.4f",
        math.deg(
            value
        )
    )

end


--------------------------------------------------
-- VECTOR MAGNITUDE
--------------------------------------------------

local function magnitude(
    value
)

    return math.sqrt(
        value.x * value.x +
        value.y * value.y +
        value.z * value.z
    )

end


--------------------------------------------------
-- DOMINANT AXIS
--------------------------------------------------

local function dominantAxis(
    value
)

    local ax =
        math.abs(
            value.x
        )


    local ay =
        math.abs(
            value.y
        )


    local az =
        math.abs(
            value.z
        )


    if ax >= ay
        and
        ax >= az then

        return "X"

    elseif ay >= ax
        and
        ay >= az then

        return "Y"

    else

        return "Z"

    end

end


--------------------------------------------------
-- READ GIMBAL ANGLES
--------------------------------------------------

local function readAngles()

    if not gimbal then
        return nil
    end


    local ok,
        values =
        safeCall(
            gimbal,
            "getAnglesRad"
        )


    if not ok
        or
        type(values) ~= "table" then

        return nil

    end


    return {
        x =
            tonumber(
                values[1]
            ) or 0,

        y =
            tonumber(
                values[2]
            ) or 0,

        z =
            tonumber(
                values[3]
            ) or 0
    }

end


--------------------------------------------------
-- READ ANGULAR RATES
--------------------------------------------------

local function readRates()

    if not gimbal then
        return nil
    end


    local ok,
        values =
        safeCall(
            gimbal,
            "getAngularRatesRad"
        )


    if not ok
        or
        type(values) ~= "table" then

        return nil

    end


    return {
        x =
            tonumber(
                values[1]
            ) or 0,

        y =
            tonumber(
                values[2]
            ) or 0,

        z =
            tonumber(
                values[3]
            ) or 0
    }

end


--------------------------------------------------
-- SET ALL VECTOR
--------------------------------------------------

local function setAllVector(
    x,
    y
)

    for _, entry in ipairs(
        thrusters
    ) do

        pcall(
            entry.device.setVector,
            x,
            y
        )

    end

end


--------------------------------------------------
-- SET ALL POWER
--------------------------------------------------

local function setAllPower(
    power
)

    for _, entry in ipairs(
        thrusters
    ) do

        pcall(
            entry.device.setPowerNormalized,
            power
        )

    end

end


--------------------------------------------------
-- CENTER
--------------------------------------------------

local function center()

    setAllVector(
        0,
        0
    )


    setAllPower(
        0
    )

end


--------------------------------------------------
-- READ ENGINE VECTORS
--------------------------------------------------

local function readEngineVectors()

    local values = {}


    for i, entry in ipairs(
        thrusters
    ) do

        local xOK,
            x =
            pcall(
                entry.device.getVectorX
            )


        local yOK,
            y =
            pcall(
                entry.device.getVectorY
            )


        if not xOK then
            x = nil
        end


        if not yOK then
            y = nil
        end


        values[i] = {
            x = x,
            y = y,
            name =
                entry.name
        }

    end


    return values

end


--------------------------------------------------
-- BUILD REPORT
--------------------------------------------------

local function buildReport()

    reportLines = {}


    reportLines[#reportLines + 1] =
        "=== CALIBRATION RESULTS ==="


    reportLines[#reportLines + 1] =
        ""


    reportLines[#reportLines + 1] =
        "POWER = " ..
        tostring(
            TEST_POWER
        )


    reportLines[#reportLines + 1] =
        "PULSE = " ..
        tostring(
            PULSE_TIME
        ) ..
        " s"


    reportLines[#reportLines + 1] =
        "THRUSTERS = " ..
        tostring(
            #thrusters
        )


    reportLines[#reportLines + 1] =
        ""


    --------------------------------------------------
    -- Results
    --------------------------------------------------

    for _, result in ipairs(
        results
    ) do

        reportLines[#reportLines + 1] =
            "================================"


        reportLines[#reportLines + 1] =
            "TEST " ..
            result.label


        reportLines[#reportLines + 1] =
            "COMMAND X=" ..
            tostring(
                result.commandX
            ) ..
            " Y=" ..
            tostring(
                result.commandY
            )


        reportLines[#reportLines + 1] =
            ""


        reportLines[#reportLines + 1] =
            "ANGLE DELTA"


        reportLines[#reportLines + 1] =
            "X = " ..
            deg(
                result.angleDelta.x
            ) ..
            " deg"


        reportLines[#reportLines + 1] =
            "Y = " ..
            deg(
                result.angleDelta.y
            ) ..
            " deg"


        reportLines[#reportLines + 1] =
            "Z = " ..
            deg(
                result.angleDelta.z
            ) ..
            " deg"


        reportLines[#reportLines + 1] =
            ""


        reportLines[#reportLines + 1] =
            "RATE DELTA"


        reportLines[#reportLines + 1] =
            "X = " ..
            fmt(
                result.rateDelta.x
            )


        reportLines[#reportLines + 1] =
            "Y = " ..
            fmt(
                result.rateDelta.y
            )


        reportLines[#reportLines + 1] =
            "Z = " ..
            fmt(
                result.rateDelta.z
            )


        reportLines[#reportLines + 1] =
            ""


        reportLines[#reportLines + 1] =
            "DOMINANT ANGLE = " ..
            result.dominantAngleAxis


        reportLines[#reportLines + 1] =
            "DOMINANT RATE = " ..
            result.dominantRateAxis


        reportLines[#reportLines + 1] =
            "ANGLE MAGNITUDE = " ..
            fmt(
                result.angleMagnitude
            )


        reportLines[#reportLines + 1] =
            ""


        if result.dominantSign >
            0 then

            reportLines[#reportLines + 1] =
                "SIGN = POSITIVE"

        elseif result.dominantSign <
            0 then

            reportLines[#reportLines + 1] =
                "SIGN = NEGATIVE"

        else

            reportLines[#reportLines + 1] =
                "SIGN = ZERO"

        end


        reportLines[#reportLines + 1] =
            ""


        --------------------------------------------------
        -- Engine feedback
        --------------------------------------------------

        reportLines[#reportLines + 1] =
            "ENGINE FEEDBACK"


        for i, engine in ipairs(
            result.engineVectors
            or
            {}
        ) do

            reportLines[#reportLines + 1] =
                "E" ..
                tostring(i) ..
                " " ..
                tostring(
                    engine.name
                ) ..
                " X=" ..
                fmt(
                    engine.x
                ) ..
                " Y=" ..
                fmt(
                    engine.y
                )

        end


        reportLines[#reportLines + 1] =
            ""

    end


    reportLines[#reportLines + 1] =
        "================================"


    reportLines[#reportLines + 1] =
        "CALIBRATION COMPLETE"


    reportLines[#reportLines + 1] =
        ""


    reportLines[#reportLines + 1] =
        "UP/DOWN = SCROLL"


    reportLines[#reportLines + 1] =
        "PAGEUP/PAGEDOWN = FAST"


    reportLines[#reportLines + 1] =
        "HOME/END = TOP/BOTTOM"


    reportLines[#reportLines + 1] =
        "Q = EXIT"

end


--------------------------------------------------
-- DRAW REPORT
--------------------------------------------------

local function drawReport()

    term.clear()


    term.setCursorPos(
        1,
        1
    )


    local width,
        height =
        term.getSize()


    local visible =
        height - 1


    local maximum =
        math.max(
            0,
            #reportLines -
            visible
        )


    if scroll < 0 then

        scroll = 0

    end


    if scroll > maximum then

        scroll = maximum

    end


    term.write(
        "CALIBRATION "
        ..
        tostring(scroll)
        ..
        "/"
        ..
        tostring(maximum)
    )


    for row = 2,
        height do

        local index =
            scroll +
            row -
            1


        term.setCursorPos(
            1,
            row
        )


        term.clearLine()


        if reportLines[index] then

            local text =
                reportLines[index]


            if #text > width then

                text =
                    text:sub(
                        1,
                        width
                    )

            end


            term.write(
                text
            )

        end

    end

end


--------------------------------------------------
-- RUN ONE TEST
--------------------------------------------------

local function runTest(
    label,
    commandX,
    commandY
)

    print("")
    print(
        "================================"
    )
    print(
        "TEST " .. label
    )
    print(
        "VECTOR X=" ..
        tostring(commandX) ..
        " Y=" ..
        tostring(commandY)
    )
    print(
        "POWER " ..
        tostring(TEST_POWER)
    )
    print(
        "PULSE " ..
        tostring(PULSE_TIME) ..
        " seconds"
    )
    print(
        "================================"
    )


    --------------------------------------------------
    -- RESET
    --------------------------------------------------

    center()

    sleep(
        SETTLE_TIME
    )


    --------------------------------------------------
    -- INITIAL SENSOR STATE
    --------------------------------------------------

    local beforeAngles =
        readAngles()


    local beforeRates =
        readRates()


    if not beforeAngles then

        print(
            "ERROR: cannot read Gimbal angles"
        )

        center()

        return nil

    end


    if not beforeRates then

        print(
            "ERROR: cannot read angular rates"
        )

        center()

        return nil

    end


    --------------------------------------------------
    -- APPLY VECTOR FIRST
    --------------------------------------------------

    setAllVector(
        commandX,
        commandY
    )


    --------------------------------------------------
    -- THEN APPLY POWER
    --------------------------------------------------

    setAllPower(
        TEST_POWER
    )


    --------------------------------------------------
    -- PULSE
    --------------------------------------------------

    sleep(
        PULSE_TIME
    )


    --------------------------------------------------
    -- STOP THRUST
    --------------------------------------------------

    center()


    --------------------------------------------------
    -- WAIT FOR COMMAND TO SETTLE
    --------------------------------------------------

    sleep(
        0.10
    )


    --------------------------------------------------
    -- SENSOR RESULT
    --------------------------------------------------

    local afterAngles =
        readAngles()


    local afterRates =
        readRates()


    if not afterAngles
        or
        not afterRates then

        print(
            "ERROR: cannot read result"
        )

        center()

        return nil

    end


    --------------------------------------------------
    -- CALCULATE DELTA
    --------------------------------------------------

    local angleDelta = {

        x =
            afterAngles.x -
            beforeAngles.x,

        y =
            afterAngles.y -
            beforeAngles.y,

        z =
            afterAngles.z -
            beforeAngles.z

    }


    local rateDelta = {

        x =
            afterRates.x -
            beforeRates.x,

        y =
            afterRates.y -
            beforeRates.y,

        z =
            afterRates.z -
            beforeRates.z

    }


    --------------------------------------------------
    -- DOMINANT AXIS
    --------------------------------------------------

    local dominant =
        dominantAxis(
            angleDelta
        )


    local dominantValue


    if dominant == "X" then

        dominantValue =
            angleDelta.x


    elseif dominant == "Y" then

        dominantValue =
            angleDelta.y


    else

        dominantValue =
            angleDelta.z

    end


    --------------------------------------------------
    -- RESULT
    --------------------------------------------------

    local result = {

        label =
            label,

        commandX =
            commandX,

        commandY =
            commandY,

        angleDelta =
            angleDelta,

        rateDelta =
            rateDelta,

        angleMagnitude =
            magnitude(
                angleDelta
            ),

        dominantAngleAxis =
            dominant,

        dominantRateAxis =
            dominantAxis(
                rateDelta
            ),

        dominantSign =
            dominantValue,

        engineVectors =
            readEngineVectors()

    }


    --------------------------------------------------
    -- CONSOLE OUTPUT
    --------------------------------------------------

    print("")


    print(
        "ANGLE DELTA"
    )


    print(
        "X " ..
        deg(
            angleDelta.x
        ) ..
        " deg"
    )


    print(
        "Y " ..
        deg(
            angleDelta.y
        ) ..
        " deg"
    )


    print(
        "Z " ..
        deg(
            angleDelta.z
        ) ..
        " deg"
    )


    print("")


    print(
        "DOMINANT AXIS: " ..
        dominant
    )


    if dominantValue > 0 then

        print(
            "SIGN: POSITIVE"
        )


    elseif dominantValue < 0 then

        print(
            "SIGN: NEGATIVE"
        )


    else

        print(
            "SIGN: ZERO"
        )

    end


    --------------------------------------------------
    -- ALWAYS STOP
    --------------------------------------------------

    center()


    return result

end


--------------------------------------------------
-- START SCREEN
--------------------------------------------------

term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "=== MISSILE CONTROL CALIBRATION ==="
)

print("")

print(
    "Rocket: UNFROZEN"
)

print(
    "Actuator: OFF"
)

print(
    "Flight: OFF"
)

print("")

print(
    "Power = " ..
    tostring(
        TEST_POWER
    )
)

print(
    "Pulse = " ..
    tostring(
        PULSE_TIME
    ) ..
    " seconds"
)

print("")

print(
    "Thrusters: scanning..."
)


--------------------------------------------------
-- SCAN
--------------------------------------------------

scanThrusters()

scanGimbal()


--------------------------------------------------
-- CHECK
--------------------------------------------------

print(
    "Thrusters found: " ..
    tostring(
        #thrusters
    )
)


if #thrusters == 0 then

    error(
        "NO LIQUID VECTOR THRUSTERS FOUND"
    )

end


if not gimbal then

    error(
        "NO GIMBAL SENSOR FOUND"
    )

end


print(
    "Gimbal Sensor: OK"
)


print("")

print(
    "Press SPACE to start"
)

print(
    "Press Q to quit"
)


--------------------------------------------------
-- WAIT START
--------------------------------------------------

while true do

    local event,
        key =
        os.pullEvent(
            "key"
        )


    if key ==
        keys.space then

        break


    elseif key ==
        keys.q then

        center()

        return

    end

end


--------------------------------------------------
-- START CALIBRATION
--------------------------------------------------

center()


--------------------------------------------------
-- TEST +X
--------------------------------------------------

local result =
    runTest(
        "+X",
        0.20,
        0
    )


if result then

    table.insert(
        results,
        result
    )

end


sleep(
    BETWEEN_TESTS
)


--------------------------------------------------
-- TEST -X
--------------------------------------------------

result =
    runTest(
        "-X",
        -0.20,
        0
    )


if result then

    table.insert(
        results,
        result
    )

end


sleep(
    BETWEEN_TESTS
)


--------------------------------------------------
-- TEST +Y
--------------------------------------------------

result =
    runTest(
        "+Y",
        0,
        0.20
    )


if result then

    table.insert(
        results,
        result
    )

end


sleep(
    BETWEEN_TESTS
)


--------------------------------------------------
-- TEST -Y
--------------------------------------------------

result =
    runTest(
        "-Y",
        0,
        -0.20
    )


if result then

    table.insert(
        results,
        result
    )

end


--------------------------------------------------
-- FINAL CENTER
--------------------------------------------------

center()


--------------------------------------------------
-- REPORT
--------------------------------------------------

buildReport()

mode =
    "RESULTS"

drawReport()


--------------------------------------------------
-- RESULT LOOP
--------------------------------------------------

while running do

    local event,
        key =
        os.pullEvent(
            "key"
        )


    --------------------------------------------------
    -- UP
    --------------------------------------------------

    if key ==
        keys.up then

        scroll =
            scroll - 1

        drawReport()


    --------------------------------------------------
    -- DOWN
    --------------------------------------------------

    elseif key ==
        keys.down then

        scroll =
            scroll + 1

        drawReport()


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

        drawReport()


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

        drawReport()


    --------------------------------------------------
    -- HOME
    --------------------------------------------------

    elseif key ==
        keys.home then

        scroll =
            0

        drawReport()


    --------------------------------------------------
    -- END
    --------------------------------------------------

    elseif key ==
        keys["end"] then

        scroll =
            #reportLines

        drawReport()


    --------------------------------------------------
    -- REDRAW
    --------------------------------------------------

    elseif key ==
        keys.r then

        buildReport()

        drawReport()


    --------------------------------------------------
    -- EXIT
    --------------------------------------------------

    elseif key ==
        keys.q then

        center()

        running =
            false

    end

end


--------------------------------------------------
-- FINAL SAFETY
--------------------------------------------------

center()


term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "CALIBRATION COMPLETE"
)

print("")

print(
    "All thrusters:"
)

print(
    "VECTOR = 0,0"
)

print(
    "POWER = 0"
)
