-- Missile Control Axis Calibration v2
-- CC:Tweaked
--
-- PURPOSE:
--   Determine the dynamic response of the rocket to
--   vector commands by measuring ANGULAR VELOCITY
--   during the thrust pulse.
--
-- REAL APIs:
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
--   Rocket must be UNFROZEN during the pulse.
--
-- TESTS:
--   +X
--   -X
--   +Y
--   -Y
--
-- TEST SETTINGS:
--   vector = +/-0.05
--   power  = 0.30
--   pulse  = 0.50 s
--
-- The test samples angular rates every 0.02 s
-- and finds the strongest signed response.
--
-- CONTROLS AFTER TEST:
--   UP / DOWN      scroll
--   PAGEUP        fast up
--   PAGEDOWN      fast down
--   HOME          top
--   END           bottom
--   R             redraw
--   Q             exit
--
-- FINAL SAFETY:
--   vector = 0,0
--   power = 0

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local TEST_VECTOR = 0.05

local TEST_POWER = 0.30

local PULSE_TIME = 0.50

local SAMPLE_TIME = 0.02

local SETTLE_TIME = 1.00

local BETWEEN_TESTS = 1.50


--------------------------------------------------
-- PERIPHERALS
--------------------------------------------------

local thrusters = {}

local gimbal = nil


--------------------------------------------------
-- RESULTS
--------------------------------------------------

local results = {}

local reportLines = {}

local scroll = 0


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

            local hasVector = false

            local hasPower = false


            for _, method in ipairs(
                methods
            ) do

                if method ==
                    "setVector" then

                    hasVector = true

                elseif method ==
                    "setPowerNormalized" then

                    hasPower = true

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

                gimbal =
                    device

                return

            end

        end

    end

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
            digits or 6
        ) ..
        "f",
        value
    )

end


--------------------------------------------------
-- DEGREE FORMAT
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
        "%.5f",
        math.deg(value)
    )

end


--------------------------------------------------
-- VECTOR MAGNITUDE
--------------------------------------------------

local function magnitude(
    x,
    y,
    z
)

    return math.sqrt(
        x * x +
        y * y +
        z * z
    )

end


--------------------------------------------------
-- READ ANGULAR RATE
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
-- READ ANGLES
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
-- SET ALL VECTORS
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
-- EMERGENCY STOP
--------------------------------------------------

local function stopAll()

    setAllVector(
        0,
        0
    )


    setAllPower(
        0
    )

end


--------------------------------------------------
-- WAIT SETTLE
--------------------------------------------------

local function settle()

    stopAll()

    sleep(
        SETTLE_TIME
    )

end


--------------------------------------------------
-- INITIALIZE BASELINE
--------------------------------------------------

local function getBaseline()

    local rates =
        readRates()


    local angles =
        readAngles()


    if not rates then

        return nil, nil

    end


    return rates, angles

end


--------------------------------------------------
-- RUN ONE DYNAMIC TEST
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
        "POWER=" ..
        tostring(TEST_POWER)
    )
    print(
        "PULSE=" ..
        tostring(PULSE_TIME) ..
        " s"
    )
    print(
        "================================"
    )


    --------------------------------------------------
    -- RESET
    --------------------------------------------------

    settle()


    --------------------------------------------------
    -- BASELINE
    --------------------------------------------------

    local baselineRates,
        baselineAngles =
        getBaseline()


    if not baselineRates then

        print(
            "ERROR: Gimbal rate unavailable"
        )


        stopAll()


        return nil

    end


    --------------------------------------------------
    -- PEAK DATA
    --------------------------------------------------

    local peak = {

        x = 0,
        y = 0,
        z = 0

    }


    local peakAbs = {

        x = 0,
        y = 0,
        z = 0

    }


    local peakTime = {

        x = 0,
        y = 0,
        z = 0

    }


    local peakAngles = {

        x = baselineAngles
            and
            baselineAngles.x
            or
            0,

        y = baselineAngles
            and
            baselineAngles.y
            or
            0,

        z = baselineAngles
            and
            baselineAngles.z
            or
            0

    }


    local sampleCount = 0


    local startTime =
        os.clock()


    --------------------------------------------------
    -- VECTOR FIRST
    --------------------------------------------------

    setAllVector(
        commandX,
        commandY
    )


    --------------------------------------------------
    -- POWER SECOND
    --------------------------------------------------

    setAllPower(
        TEST_POWER
    )


    --------------------------------------------------
    -- SAMPLE LOOP
    --------------------------------------------------

    while true do

        local elapsed =
            os.clock() -
            startTime


        if elapsed >=
            PULSE_TIME then

            break

        end


        local rates =
            readRates()


        local angles =
            readAngles()


        if rates then

            sampleCount =
                sampleCount + 1


            --------------------------------------------------
            -- DELTA FROM BASELINE
            --------------------------------------------------

            local dx =
                rates.x -
                baselineRates.x


            local dy =
                rates.y -
                baselineRates.y


            local dz =
                rates.z -
                baselineRates.z


            --------------------------------------------------
            -- PEAK X
            --------------------------------------------------

            if math.abs(dx) >
                peakAbs.x then

                peakAbs.x =
                    math.abs(dx)

                peak.x =
                    dx

                peakTime.x =
                    elapsed


                if angles then

                    peakAngles.x =
                        angles.x

                end

            end


            --------------------------------------------------
            -- PEAK Y
            --------------------------------------------------

            if math.abs(dy) >
                peakAbs.y then

                peakAbs.y =
                    math.abs(dy)

                peak.y =
                    dy

                peakTime.y =
                    elapsed


                if angles then

                    peakAngles.y =
                        angles.y

                end

            end


            --------------------------------------------------
            -- PEAK Z
            --------------------------------------------------

            if math.abs(dz) >
                peakAbs.z then

                peakAbs.z =
                    math.abs(dz)

                peak.z =
                    dz

                peakTime.z =
                    elapsed


                if angles then

                    peakAngles.z =
                        angles.z

                end

            end

        end


        sleep(
            SAMPLE_TIME
        )

    end


    --------------------------------------------------
    -- STOP
    --------------------------------------------------

    stopAll()


    --------------------------------------------------
    -- RESULT
    --------------------------------------------------

    local strongestAxis =
        "NONE"


    local strongestValue =
        0


    if peakAbs.x >
        strongestValue then

        strongestValue =
            peakAbs.x

        strongestAxis =
            "X"

    end


    if peakAbs.y >
        strongestValue then

        strongestValue =
            peakAbs.y

        strongestAxis =
            "Y"

    end


    if peakAbs.z >
        strongestValue then

        strongestValue =
            peakAbs.z

        strongestAxis =
            "Z"

    end


    local strongestSigned =
        0


    if strongestAxis ==
        "X" then

        strongestSigned =
            peak.x


    elseif strongestAxis ==
        "Y" then

        strongestSigned =
            peak.y


    elseif strongestAxis ==
        "Z" then

        strongestSigned =
            peak.z

    end


    local result = {

        label =
            label,

        commandX =
            commandX,

        commandY =
            commandY,

        baselineRates =
            baselineRates,

        peakRate =
            peak,

        peakAbs =
            peakAbs,

        peakTime =
            peakTime,

        peakAngles =
            peakAngles,

        strongestAxis =
            strongestAxis,

        strongestSigned =
            strongestSigned,

        strongestMagnitude =
            strongestValue,

        sampleCount =
            sampleCount

    }


    --------------------------------------------------
    -- CONSOLE
    --------------------------------------------------

    print("")


    print(
        "PEAK ANGULAR RATE DELTA"
    )


    print(
        "X = " ..
        fmt(
            peak.x
        )
    )


    print(
        "Y = " ..
        fmt(
            peak.y
        )
    )


    print(
        "Z = " ..
        fmt(
            peak.z
        )
    )


    print("")


    print(
        "PEAK DEGREES/SEC"
    )


    print(
        "X = " ..
        deg(
            peak.x
        ) ..
        " deg/s"
    )


    print(
        "Y = " ..
        deg(
            peak.y
        ) ..
        " deg/s"
    )


    print(
        "Z = " ..
        deg(
            peak.z
        ) ..
        " deg/s"
    )


    print("")


    print(
        "STRONGEST AXIS = " ..
        strongestAxis
    )


    print(
        "STRONGEST SIGN = " ..
        (
            strongestSigned >= 0
            and
            "+"
            or
            "-"
        )
    )


    print(
        "SAMPLES = " ..
        tostring(
            sampleCount
        )
    )


    stopAll()


    return result

end


--------------------------------------------------
-- BUILD REPORT
--------------------------------------------------

local function buildReport()

    reportLines = {}


    reportLines[#reportLines + 1] =
        "=== DYNAMIC CALIBRATION ==="


    reportLines[#reportLines + 1] =
        ""


    reportLines[#reportLines + 1] =
        "VECTOR = +/-" ..
        tostring(
            TEST_VECTOR
        )


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
        "SAMPLE = " ..
        tostring(
            SAMPLE_TIME
        ) ..
        " s"


    reportLines[#reportLines + 1] =
        ""


    --------------------------------------------------
    -- RESULTS
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
            "PEAK RATE DELTA"


        reportLines[#reportLines + 1] =
            "X = " ..
            fmt(
                result.peakRate.x
            )


        reportLines[#reportLines + 1] =
            "Y = " ..
            fmt(
                result.peakRate.y
            )


        reportLines[#reportLines + 1] =
            "Z = " ..
            fmt(
                result.peakRate.z
            )


        reportLines[#reportLines + 1] =
            ""


        reportLines[#reportLines + 1] =
            "PEAK DEG/SEC"


        reportLines[#reportLines + 1] =
            "X = " ..
            deg(
                result.peakRate.x
            )


        reportLines[#reportLines + 1] =
            "Y = " ..
            deg(
                result.peakRate.y
            )


        reportLines[#reportLines + 1] =
            "Z = " ..
            deg(
                result.peakRate.z
            )


        reportLines[#reportLines + 1] =
            ""


        reportLines[#reportLines + 1] =
            "PEAK TIME"


        reportLines[#reportLines + 1] =
            "X = " ..
            fmt(
                result.peakTime.x,
                3
            ) ..
            " s"


        reportLines[#reportLines + 1] =
            "Y = " ..
            fmt(
                result.peakTime.y,
                3
            ) ..
            " s"


        reportLines[#reportLines + 1] =
            "Z = " ..
            fmt(
                result.peakTime.z,
                3
            ) ..
            " s"


        reportLines[#reportLines + 1] =
            ""


        reportLines[#reportLines + 1] =
            "STRONGEST AXIS = " ..
            result.strongestAxis


        reportLines[#reportLines + 1] =
            "STRONGEST SIGN = " ..
            (
                result.strongestSigned >= 0
                and
                "+"
                or
                "-"
            )


        reportLines[#reportLines + 1] =
            "STRONGEST RATE = " ..
            deg(
                result.strongestMagnitude
            ) ..
            " deg/s"


        reportLines[#reportLines + 1] =
            "SAMPLES = " ..
            tostring(
                result.sampleCount
            )


        reportLines[#reportLines + 1] =
            ""

    end


    --------------------------------------------------
    -- CONCLUSION
    --------------------------------------------------

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
        "CALIBRATION " ..
        tostring(
            scroll
        ) ..
        "/" ..
        tostring(
            maximum
        )
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
-- STARTUP SCREEN
--------------------------------------------------

term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "=== DYNAMIC CONTROL CALIBRATION ==="
)

print("")

print(
    "ROCKET: UNFROZEN"
)

print(
    "ACTUATOR: OFF"
)

print(
    "FLIGHT: OFF"
)

print("")

print(
    "VECTOR = +/-" ..
    tostring(
        TEST_VECTOR
    )
)

print(
    "POWER = " ..
    tostring(
        TEST_POWER
    )
)

print(
    "PULSE = " ..
    tostring(
        PULSE_TIME
    ) ..
    " s"
)

print(
    "SAMPLE = " ..
    tostring(
        SAMPLE_TIME
    ) ..
    " s"
)

print("")


--------------------------------------------------
-- SCAN
--------------------------------------------------

scanThrusters()

scanGimbal()


--------------------------------------------------
-- CHECK
--------------------------------------------------

print(
    "THRUSTERS FOUND: " ..
    tostring(
        #thrusters
    )
)


if #thrusters == 0 then

    error(
        "NO VECTOR THRUSTERS FOUND"
    )

end


if not gimbal then

    error(
        "NO GIMBAL SENSOR FOUND"
    )

end


print(
    "GIMBAL SENSOR: OK"
)

print("")

print(
    "The rocket must be FREE."
)

print(
    "Press SPACE to start."
)

print(
    "Press Q to quit."
)


--------------------------------------------------
-- WAIT
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

        stopAll()

        return

    end

end


--------------------------------------------------
-- INITIAL SAFE STATE
--------------------------------------------------

stopAll()

sleep(
    1.0
)


--------------------------------------------------
-- TEST +X
--------------------------------------------------

local result =
    runTest(
        "+X",
        TEST_VECTOR,
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
        -TEST_VECTOR,
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
        TEST_VECTOR
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
        -TEST_VECTOR
    )


if result then

    table.insert(
        results,
        result
    )

end


--------------------------------------------------
-- FINAL STOP
--------------------------------------------------

stopAll()


--------------------------------------------------
-- BUILD REPORT
--------------------------------------------------

buildReport()


--------------------------------------------------
-- RESULT SCREEN
--------------------------------------------------

drawReport()


--------------------------------------------------
-- RESULT LOOP
--------------------------------------------------

while true do

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

        local _, height =
            term.getSize()


        scroll =
            scroll -
            math.max(
                1,
                height - 2
            )


        drawReport()


    --------------------------------------------------
    -- PAGE DOWN
    --------------------------------------------------

    elseif key ==
        keys.pageDown then

        local _, height =
            term.getSize()


        scroll =
            scroll +
            math.max(
                1,
                height - 2
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

        break

    end

end


--------------------------------------------------
-- FINAL SAFETY
--------------------------------------------------

stopAll()


term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "DYNAMIC CALIBRATION COMPLETE"
)

print("")

print(
    "VECTOR = 0,0"
)

print(
    "POWER = 0"
)