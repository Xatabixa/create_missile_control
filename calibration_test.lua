-- Missile Control Axis Calibration v3
-- CC:Tweaked
--
-- PURPOSE:
--   Determine the dynamic response of the rocket
--   to vector commands using Gimbal Sensor.
--
-- IMPORTANT:
--   DO NOT run launcher.lua at the same time.
--   actuator.lua must NOT be running.
--
--   Rocket must be UNFROZEN during the test pulse.
--
-- TEST:
--   +X
--   -X
--   +Y
--   -Y
--
-- POWER:
--   X axis = 0.10
--   Y axis = 0.20
--
-- VECTOR:
--   +/-0.05
--
-- PULSE:
--   2.0 seconds
--
-- SAMPLE:
--   every 0.05 seconds
--
-- SETTLE:
--   3.0 seconds between tests
--
-- The program records:
--   - baseline angular rate
--   - every angular-rate sample
--   - peak rate delta
--   - average rate delta during second half
--   - strongest axis
--   - sign
--
-- CONTROLS AFTER TEST:
--   UP / DOWN     scroll
--   PAGEUP        fast up
--   PAGEDOWN      fast down
--   HOME          top
--   END           bottom
--   R             redraw
--   Q             exit
--
-- SAFETY:
--   Every test ends with:
--      vector = 0,0
--      power  = 0
--
--   No actuator.lua is used.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local TEST_VECTOR = 0.05

local X_POWER = 0.10
local Y_POWER = 0.20

local PULSE_TIME = 2.0
local SAMPLE_TIME = 0.05
local SETTLE_TIME = 3.0
local AFTER_STOP_TIME = 0.20

--------------------------------------------------
-- DEVICES
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

                gimbal =
                    device

                return

            end

        end

    end

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
            digits or 6
        ) ..
        "f",
        value
    )

end

--------------------------------------------------
-- DEG/S
--------------------------------------------------

local function degPerSecond(
    value
)

    value =
        tonumber(value)

    if not value then

        return "---"

    end

    return string.format(
        "%.6f",
        math.deg(value)
    )

end

--------------------------------------------------
-- READ RATES
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
-- SET VECTOR
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
-- SET POWER
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
-- STOP
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
-- SETTLE
--------------------------------------------------

local function settle()

    stopAll()

    sleep(
        SETTLE_TIME
    )

end

--------------------------------------------------
-- AVERAGE
--------------------------------------------------

local function average(
    values,
    key
)

    if #values == 0 then

        return 0

    end

    local sum = 0

    for _, value in ipairs(
        values
    ) do

        sum =
            sum +
            value[key]

    end

    return
        sum /
        #values

end

--------------------------------------------------
-- FIND STRONGEST
--------------------------------------------------

local function strongestAxis(
    value
)

    local ax =
        math.abs(value.x)

    local ay =
        math.abs(value.y)

    local az =
        math.abs(value.z)

    if ax >= ay
        and
        ax >= az then

        return "X",
            value.x

    elseif ay >= ax
        and
        ay >= az then

        return "Y",
            value.y

    else

        return "Z",
            value.z

    end

end

--------------------------------------------------
-- RUN TEST
--------------------------------------------------

local function runTest(
    label,
    commandX,
    commandY,
    power
)

    print("")
    print(
        "================================"
    )

    print(
        "TEST " ..
        label
    )

    print(
        "VECTOR X=" ..
        tostring(commandX) ..
        " Y=" ..
        tostring(commandY)
    )

    print(
        "POWER=" ..
        tostring(power)
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

    local baseline =
        readRates()

    local baselineAngles =
        readAngles()

    if not baseline then

        print(
            "ERROR: Gimbal Sensor unavailable"
        )

        stopAll()

        return nil

    end

    --------------------------------------------------
    -- STORAGE
    --------------------------------------------------

    local samples = {}

    local startTime =
        os.clock()

    local secondHalfStart =
        PULSE_TIME / 2

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
        power
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

            table.insert(
                samples,
                {
                    time = elapsed,

                    x =
                        rates.x -
                        baseline.x,

                    y =
                        rates.y -
                        baseline.y,

                    z =
                        rates.z -
                        baseline.z,

                    angleX =
                        angles
                        and
                        (
                            angles.x -
                            (
                                baselineAngles
                                and
                                baselineAngles.x
                                or
                                0
                            )
                        )
                        or
                        0,

                    angleY =
                        angles
                        and
                        (
                            angles.y -
                            (
                                baselineAngles
                                and
                                baselineAngles.y
                                or
                                0
                            )
                        )
                        or
                        0,

                    angleZ =
                        angles
                        and
                        (
                            angles.z -
                            (
                                baselineAngles
                                and
                                baselineAngles.z
                                or
                                0
                            )
                        )
                        or
                        0
                }
            )

        end

        sleep(
            SAMPLE_TIME
        )

    end

    --------------------------------------------------
    -- STOP IMMEDIATELY
    --------------------------------------------------

    stopAll()

    sleep(
        AFTER_STOP_TIME
    )

    --------------------------------------------------
    -- SEPARATE SECOND HALF
    --------------------------------------------------

    local secondHalf = {}

    for _, sample in ipairs(
        samples
    ) do

        if sample.time >=
            secondHalfStart then

            table.insert(
                secondHalf,
                sample
            )

        end

    end

    --------------------------------------------------
    -- PEAK
    --------------------------------------------------

    local peak = {

        x = 0,
        y = 0,
        z = 0

    }

    local peakTime = {

        x = 0,
        y = 0,
        z = 0

    }

    --------------------------------------------------
    -- PROCESS PEAK
    --------------------------------------------------

    for _, sample in ipairs(
        samples
    ) do

        if math.abs(sample.x) >
            math.abs(peak.x) then

            peak.x =
                sample.x

            peakTime.x =
                sample.time

        end

        if math.abs(sample.y) >
            math.abs(peak.y) then

            peak.y =
                sample.y

            peakTime.y =
                sample.time

        end

        if math.abs(sample.z) >
            math.abs(peak.z) then

            peak.z =
                sample.z

            peakTime.z =
                sample.time

        end

    end

    --------------------------------------------------
    -- AVERAGE RATE
    --------------------------------------------------

    local avg = {

        x =
            average(
                secondHalf,
                "x"
            ),

        y =
            average(
                secondHalf,
                "y"
            ),

        z =
            average(
                secondHalf,
                "z"
            )

    }

    --------------------------------------------------
    -- AVERAGE ABSOLUTE RATE
    --------------------------------------------------

    local avgAbs = {

        x = 0,
        y = 0,
        z = 0

    }

    for _, sample in ipairs(
        secondHalf
    ) do

        avgAbs.x =
            avgAbs.x +
            math.abs(
                sample.x
            )

        avgAbs.y =
            avgAbs.y +
            math.abs(
                sample.y
            )

        avgAbs.z =
            avgAbs.z +
            math.abs(
                sample.z
            )

    end

    if #secondHalf > 0 then

        avgAbs.x =
            avgAbs.x /
            #secondHalf

        avgAbs.y =
            avgAbs.y /
            #secondHalf

        avgAbs.z =
            avgAbs.z /
            #secondHalf

    end

    --------------------------------------------------
    -- AVERAGE ANGLE CHANGE
    --------------------------------------------------

    local angleAverage = {

        x = 0,
        y = 0,
        z = 0

    }

    if #secondHalf > 0 then

        for _, sample in ipairs(
            secondHalf
        ) do

            angleAverage.x =
                angleAverage.x +
                sample.angleX

            angleAverage.y =
                angleAverage.y +
                sample.angleY

            angleAverage.z =
                angleAverage.z +
                sample.angleZ

        end

        angleAverage.x =
            angleAverage.x /
            #secondHalf

        angleAverage.y =
            angleAverage.y /
            #secondHalf

        angleAverage.z =
            angleAverage.z /
            #secondHalf

    end

    --------------------------------------------------
    -- STRONGEST PEAK
    --------------------------------------------------

    local peakAxis,
        peakSigned =
        strongestAxis(
            peak
        )

    --------------------------------------------------
    -- STRONGEST AVERAGE
    --------------------------------------------------

    local avgAxis,
        avgSigned =
        strongestAxis(
            avg
        )

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

        power =
            power,

        baseline =
            baseline,

        peak =
            peak,

        peakTime =
            peakTime,

        average =
            avg,

        averageAbs =
            avgAbs,

        angleAverage =
            angleAverage,

        peakAxis =
            peakAxis,

        peakSigned =
            peakSigned,

        averageAxis =
            avgAxis,

        averageSigned =
            avgSigned,

        sampleCount =
            #samples,

        secondHalfSamples =
            #secondHalf

    }

    --------------------------------------------------
    -- OUTPUT
    --------------------------------------------------

    print("")

    print(
        "PEAK RATE DELTA"
    )

    print(
        "X = " ..
        degPerSecond(
            peak.x
        ) ..
        " deg/s"
    )

    print(
        "Y = " ..
        degPerSecond(
            peak.y
        ) ..
        " deg/s"
    )

    print(
        "Z = " ..
        degPerSecond(
            peak.z
        ) ..
        " deg/s"
    )

    print("")

    print(
        "AVERAGE RATE, SECOND HALF"
    )

    print(
        "X = " ..
        degPerSecond(
            avg.x
        ) ..
        " deg/s"
    )

    print(
        "Y = " ..
        degPerSecond(
            avg.y
        ) ..
        " deg/s"
    )

    print(
        "Z = " ..
        degPerSecond(
            avg.z
        ) ..
        " deg/s"
    )

    print("")

    print(
        "AVERAGE ABSOLUTE RATE"
    )

    print(
        "X = " ..
        degPerSecond(
            avgAbs.x
        ) ..
        " deg/s"
    )

    print(
        "Y = " ..
        degPerSecond(
            avgAbs.y
        ) ..
        " deg/s"
    )

    print(
        "Z = " ..
        degPerSecond(
            avgAbs.z
        ) ..
        " deg/s"
    )

    print("")

    print(
        "AVERAGE ANGLE CHANGE"
    )

    print(
        "X = " ..
        fmt(
            math.deg(
                angleAverage.x
            ),
            5
        ) ..
        " deg"
    )

    print(
        "Y = " ..
        fmt(
            math.deg(
                angleAverage.y
            ),
            5
        ) ..
        " deg"
    )

    print(
        "Z = " ..
        fmt(
            math.deg(
                angleAverage.z
            ),
            5
        ) ..
        " deg"
    )

    print("")

    print(
        "PEAK AXIS = " ..
        peakAxis
    )

    print(
        "PEAK SIGN = " ..
        (
            peakSigned >= 0
            and
            "+"
            or
            "-"
        )
    )

    print(
        "AVERAGE AXIS = " ..
        avgAxis
    )

    print(
        "AVERAGE SIGN = " ..
        (
            avgSigned >= 0
            and
            "+"
            or
            "-"
        )
    )

    print("")

    print(
        "SAMPLES = " ..
        tostring(
            #samples
        )
    )

    print(
        "2ND HALF = " ..
        tostring(
            #secondHalf
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
        "=== DYNAMIC CALIBRATION V3 ==="

    reportLines[#reportLines + 1] =
        ""

    reportLines[#reportLines + 1] =
        "VECTOR = +/-" ..
        tostring(
            TEST_VECTOR
        )

    reportLines[#reportLines + 1] =
        "X POWER = " ..
        tostring(
            X_POWER
        )

    reportLines[#reportLines + 1] =
        "Y POWER = " ..
        tostring(
            Y_POWER
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
        "SETTLE = " ..
        tostring(
            SETTLE_TIME
        ) ..
        " s"

    reportLines[#reportLines + 1] =
        ""

    --------------------------------------------------
    -- EACH TEST
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
            "VECTOR X=" ..
            tostring(
                result.commandX
            ) ..
            " Y=" ..
            tostring(
                result.commandY
            )

        reportLines[#reportLines + 1] =
            "POWER=" ..
            tostring(
                result.power
            )

        reportLines[#reportLines + 1] =
            ""

        reportLines[#reportLines + 1] =
            "PEAK DEG/SEC"

        reportLines[#reportLines + 1] =
            "X = " ..
            degPerSecond(
                result.peak.x
            )

        reportLines[#reportLines + 1] =
            "Y = " ..
            degPerSecond(
                result.peak.y
            )

        reportLines[#reportLines + 1] =
            "Z = " ..
            degPerSecond(
                result.peak.z
            )

        reportLines[#reportLines + 1] =
            ""

        reportLines[#reportLines + 1] =
            "AVERAGE DEG/SEC"

        reportLines[#reportLines + 1] =
            "X = " ..
            degPerSecond(
                result.average.x
            )

        reportLines[#reportLines + 1] =
            "Y = " ..
            degPerSecond(
                result.average.y
            )

        reportLines[#reportLines + 1] =
            "Z = " ..
            degPerSecond(
                result.average.z
            )

        reportLines[#reportLines + 1] =
            ""

        reportLines[#reportLines + 1] =
            "ABS AVG DEG/SEC"

        reportLines[#reportLines + 1] =
            "X = " ..
            degPerSecond(
                result.averageAbs.x
            )

        reportLines[#reportLines + 1] =
            "Y = " ..
            degPerSecond(
                result.averageAbs.y
            )

        reportLines[#reportLines + 1] =
            "Z = " ..
            degPerSecond(
                result.averageAbs.z
            )

        reportLines[#reportLines + 1] =
            ""

        reportLines[#reportLines + 1] =
            "ANGLE CHANGE"

        reportLines[#reportLines + 1] =
            "X = " ..
            fmt(
                math.deg(
                    result.angleAverage.x
                ),
                5
            ) ..
            " deg"

        reportLines[#reportLines + 1] =
            "Y = " ..
            fmt(
                math.deg(
                    result.angleAverage.y
                ),
                5
            ) ..
            " deg"

        reportLines[#reportLines + 1] =
            "Z = " ..
            fmt(
                math.deg(
                    result.angleAverage.z
                ),
                5
            ) ..
            " deg"

        reportLines[#reportLines + 1] =
            ""

        reportLines[#reportLines + 1] =
            "PEAK AXIS = " ..
            result.peakAxis

        reportLines[#reportLines + 1] =
            "PEAK SIGN = " ..
            (
                result.peakSigned >= 0
                and
                "+"
                or
                "-"
            )

        reportLines[#reportLines + 1] =
            "AVG AXIS = " ..
            result.averageAxis

        reportLines[#reportLines + 1] =
            "AVG SIGN = " ..
            (
                result.averageSigned >= 0
                and
                "+"
                or
                "-"
            )

        reportLines[#reportLines + 1] =
            "SAMPLES = " ..
            tostring(
                result.sampleCount
            )

        reportLines[#reportLines + 1] =
            "2ND HALF = " ..
            tostring(
                result.secondHalfSamples
            )

        reportLines[#reportLines + 1] =
            ""

    end

    --------------------------------------------------
    -- FOOTER
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
-- DRAW
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
-- STARTUP
--------------------------------------------------

term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "=== DYNAMIC CALIBRATION V3 ==="
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
    "X POWER = " ..
    tostring(
        X_POWER
    )
)

print(
    "Y POWER = " ..
    tostring(
        Y_POWER
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

print(
    "SETTLE = " ..
    tostring(
        SETTLE_TIME
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
-- TEST +X
--------------------------------------------------

local result =
    runTest(
        "+X",
        TEST_VECTOR,
        0,
        X_POWER
    )


if result then

    table.insert(
        results,
        result
    )

end


--------------------------------------------------
-- BETWEEN
--------------------------------------------------

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
        0,
        X_POWER
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
        TEST_VECTOR,
        Y_POWER
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
        -TEST_VECTOR,
        Y_POWER
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


    if key ==
        keys.up then

        scroll =
            scroll - 1

        drawReport()


    elseif key ==
        keys.down then

        scroll =
            scroll + 1

        drawReport()


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


    elseif key ==
        keys.home then

        scroll =
            0

        drawReport()


    elseif key ==
        keys["end"] then

        scroll =
            #reportLines

        drawReport()


    elseif key ==
        keys.r then

        buildReport()

        drawReport()


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