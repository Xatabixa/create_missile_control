-- Missile Control Axis Calibration
-- CC:Tweaked
--
-- Purpose:
--   Determine the physical relationship between:
--
--       Thruster vector X/Y
--              ↓
--       Rocket rotation
--
-- Uses REAL confirmed APIs:
--
-- Liquid Vector Thruster:
--   setVector
--   setPowerNormalized
--   getVectorX
--   getVectorY
--
-- Gimbal Sensor:
--   getAnglesRad
--   getAngularRatesRad
--
-- IMPORTANT:
--   DO NOT run launcher.lua at the same time.
--   actuator.lua must NOT be running.
--
-- IMPORTANT:
--   Rocket must be UNFROZEN during the actual pulse.
--
-- SAFETY:
--   Very low power is used.
--   Every test ends with vector=0 and power=0.
--
-- Controls:
--   SPACE = start calibration
--   R     = repeat
--   Q     = quit
--
-- The program automatically tests:
--   +X
--   -X
--   +Y
--   -Y
--
-- After each pulse it returns the engines to zero.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local TEST_POWER = 0.03

local PULSE_TIME = 0.20

local SETTLE_TIME = 0.50

local BETWEEN_TESTS = 0.75


--------------------------------------------------
-- PERIPHERALS
--------------------------------------------------

local thrusters = {}

local gimbal = nil

local running = true


--------------------------------------------------
-- RESULTS
--------------------------------------------------

local results = {}


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


    return true, a, b, c, d

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

                end


                if method ==
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
        "%.5f",
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
        "%.3f",
        math.deg(value)
    )

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
            )
            or
            0,

        y =
            tonumber(
                values[2]
            )
            or
            0,

        z =
            tonumber(
                values[3]
            )
            or
            0

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
            )
            or
            0,

        y =
            tonumber(
                values[2]
            )
            or
            0,

        z =
            tonumber(
                values[3]
            )
            or
            0

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
-- SAFE CENTER
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
-- SHOW ENGINE STATE
--------------------------------------------------

local function showEngineState()

    print("")
    print("CURRENT ENGINES:")


    for i, entry in ipairs(
        thrusters
    ) do

        local okX,
            x =
            pcall(
                entry.device.getVectorX
            )


        local okY,
            y =
            pcall(
                entry.device.getVectorY
            )


        if not okX then
            x = nil
        end


        if not okY then
            y = nil
        end


        print(
            "E" ..
            tostring(i) ..
            " " ..
            entry.name ..
            " X=" ..
            fmt(x) ..
            " Y=" ..
            fmt(y)
        )

    end

end


--------------------------------------------------
-- WAIT FOR SETTLE
--------------------------------------------------

local function settle()

    center()

    sleep(
        SETTLE_TIME
    )

end


--------------------------------------------------
-- DELTA
--------------------------------------------------

local function delta(
    before,
    after
)

    return {

        x =
            after.x -
            before.x,

        y =
            after.y -
            before.y,

        z =
            after.z -
            before.z

    }

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
        math.abs(value.x)

    local ay =
        math.abs(value.y)

    local az =
        math.abs(value.z)


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
-- RUN ONE TEST
--------------------------------------------------

local function runTest(
    label,
    x,
    y
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
        tostring(x) ..
        " Y=" ..
        tostring(y)
    )

    print(
        "POWER " ..
        tostring(TEST_POWER)
    )

    print(
        "PULSE " ..
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
    -- INITIAL VALUES
    --------------------------------------------------

    local beforeAngles =
        readAngles()


    local beforeRates =
        readRates()


    if not beforeAngles then

        print(
            "ERROR: Gimbal Sensor unavailable"
        )


        return nil

    end


    if not beforeRates then

        print(
            "ERROR: Angular rates unavailable"
        )


        return nil

    end


    --------------------------------------------------
    -- APPLY POWER
    --------------------------------------------------

    setAllPower(
        TEST_POWER
    )


    --------------------------------------------------
    -- APPLY VECTOR
    --------------------------------------------------

    setAllVector(
        x,
        y
    )


    --------------------------------------------------
    -- PULSE
    --------------------------------------------------

    sleep(
        PULSE_TIME
    )


    --------------------------------------------------
    -- STOP IMMEDIATELY
    --------------------------------------------------

    center()


    --------------------------------------------------
    -- READ RESULT
    --------------------------------------------------

    local afterAngles =
        readAngles()


    local afterRates =
        readRates()


    if not afterAngles
        or
        not afterRates then

        print(
            "ERROR: Could not read Gimbal Sensor"
        )


        center()


        return nil

    end


    --------------------------------------------------
    -- DELTAS
    --------------------------------------------------

    local angleDelta =
        delta(
            beforeAngles,
            afterAngles
        )


    local rateDelta =
        delta(
            beforeRates,
            afterRates
        )


    local result = {

        label = label,

        commandX = x,

        commandY = y,

        angleDelta =
            angleDelta,

        rateDelta =
            rateDelta,

        angleMagnitude =
            magnitude(
                angleDelta
            ),

        rateMagnitude =
            magnitude(
                rateDelta
            ),

        dominantAngleAxis =
            dominantAxis(
                angleDelta
            ),

        dominantRateAxis =
            dominantAxis(
                rateDelta
            )

    }


    --------------------------------------------------
    -- DISPLAY RESULT
    --------------------------------------------------

    print("")


    print(
        "ANGLE DELTA:"
    )


    print(
        "X " ..
        deg(angleDelta.x) ..
        " deg"
    )


    print(
        "Y " ..
        deg(angleDelta.y) ..
        " deg"
    )


    print(
        "Z " ..
        deg(angleDelta.z) ..
        " deg"
    )


    print("")


    print(
        "RATE DELTA:"
    )


    print(
        "X " ..
        fmt(rateDelta.x)
    )


    print(
        "Y " ..
        fmt(rateDelta.y)
    )


    print(
        "Z " ..
        fmt(rateDelta.z)
    )


    print("")


    print(
        "DOMINANT ANGLE AXIS: " ..
        result.dominantAngleAxis
    )


    print(
        "DOMINANT RATE AXIS: " ..
        result.dominantRateAxis
    )


    --------------------------------------------------
    -- SIGN
    --------------------------------------------------

    local dominantValue


    if result.dominantAngleAxis ==
        "X" then

        dominantValue =
            angleDelta.x


    elseif result.dominantAngleAxis ==
        "Y" then

        dominantValue =
            angleDelta.y


    else

        dominantValue =
            angleDelta.z

    end


    if dominantValue > 0 then

        print(
            "DIRECTION: POSITIVE"
        )


    elseif dominantValue < 0 then

        print(
            "DIRECTION: NEGATIVE"
        )


    else

        print(
            "DIRECTION: NO SIGNIFICANT RESPONSE"
        )

    end


    --------------------------------------------------
    -- KEEP SAFE
    --------------------------------------------------

    center()


    return result

end


--------------------------------------------------
-- SHOW FINAL SUMMARY
--------------------------------------------------

local function showSummary()

    print("")
    print("")
    print("================================")
    print("       CALIBRATION SUMMARY")
    print("================================")


    for _, result in ipairs(
        results
    ) do

        print("")


        print(
            result.label ..
            "  VECTOR=(" ..
            tostring(result.commandX) ..
            "," ..
            tostring(result.commandY) ..
            ")"
        )


        print(
            "ANGLE AXIS = " ..
            result.dominantAngleAxis
        )


        local value


        if result.dominantAngleAxis ==
            "X" then

            value =
                result.angleDelta.x


        elseif result.dominantAngleAxis ==
            "Y" then

            value =
                result.angleDelta.y


        else

            value =
                result.angleDelta.z

        end


        print(
            "ANGLE DELTA = " ..
            deg(value) ..
            " deg"
        )


        if value > 0 then

            print(
                "SIGN = +"
            )

        elseif value < 0 then

            print(
                "SIGN = -"
            )

        else

            print(
                "SIGN = 0"
            )

        end

    end


    print("")
    print("================================")
    print("ALL ENGINES SET TO ZERO")
    print("================================")

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
    "=== MISSILE CONTROL CALIBRATION ==="
)

print("")

print(
    "ROCKET MUST BE UNFROZEN"
)

print(
    "ACTUATOR MUST NOT BE RUNNING"
)

print("")

print(
    "Power: " ..
    tostring(TEST_POWER)
)

print(
    "Pulse: " ..
    tostring(PULSE_TIME) ..
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
        "NO LIQUID VECTOR THRUSTERS"
    )

end


if not gimbal then

    error(
        "NO GIMBAL SENSOR"
    )

end


print(
    "GIMBAL SENSOR: OK"
)


showEngineState()


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

        center()

        return

    end

end


--------------------------------------------------
-- CALIBRATION
--------------------------------------------------

center()


--------------------------------------------------
-- X POSITIVE
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


--------------------------------------------------
-- X NEGATIVE
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


--------------------------------------------------
-- Y POSITIVE
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


--------------------------------------------------
-- Y NEGATIVE
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
-- FINAL SAFETY
--------------------------------------------------

center()


--------------------------------------------------
-- SUMMARY
--------------------------------------------------

showSummary()


--------------------------------------------------
-- EXIT
--------------------------------------------------

print("")
print(
    "Press any key to exit."
)


os.pullEvent(
    "key"
)


center()


term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "CALIBRATION COMPLETE"
)