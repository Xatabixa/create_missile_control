-- VERTICAL FLIGHT STABILIZATION TEST
-- CC:Tweaked
--
-- STANDALONE
-- NO require()
--
-- Controls:
--   Q = STOP
--
-- Controls both:
--   THRUST: 0.0 .. 1.0
--   NOZZLE: -0.250 .. +0.250
--
-- The rocket should start upright.
-- Nose parallel to Y axis.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

--------------------------------------------------
-- THRUST
--------------------------------------------------

local START_THRUST = 0.15
local MAX_THRUST = 0.30
local MIN_THRUST = 0.05

local THRUST_RAMP = 0.02

--------------------------------------------------
-- NOZZLE
--------------------------------------------------

local MAX_VECTOR = 0.250

--------------------------------------------------
-- STABILIZATION
--------------------------------------------------

local ANGLE_KP = 0.50
local RATE_KD = 0.12

--------------------------------------------------
-- IMPULSE
--------------------------------------------------

local IMPULSE_MIN = 0.06
local IMPULSE_MAX = 0.250

local IMPULSE_TIME = 0.20
local IMPULSE_COOLDOWN = 0.15

--------------------------------------------------
-- ERROR LIMITS
--------------------------------------------------

local SMALL_ERROR = math.rad(0.5)
local MEDIUM_ERROR = math.rad(2.0)
local LARGE_ERROR = math.rad(5.0)

--------------------------------------------------
-- ANGULAR RATE LIMITS
--------------------------------------------------

local HIGH_RATE = math.rad(15.0)
local CRITICAL_RATE = math.rad(30.0)

--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function clamp(value, minimum, maximum)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end


local function sign(value)

    if value > 0 then
        return 1
    end

    if value < 0 then
        return -1
    end

    return 0
end


local function degrees(radians)

    return radians * 180 / math.pi

end


local function normalizeAngle(angle)

    while angle > math.pi do
        angle = angle - math.pi * 2
    end

    while angle < -math.pi do
        angle = angle + math.pi * 2
    end

    return angle

end

--------------------------------------------------
-- FIND GIMBAL SENSOR
--------------------------------------------------

local gimbal = nil
local gimbalName = nil

for _, name in ipairs(peripheral.getNames()) do

    if peripheral.hasType(
        name,
        "gimbal_sensor"
    ) then

        local device =
            peripheral.wrap(name)

        if device then

            gimbal = device
            gimbalName = name

            break
        end
    end
end

--------------------------------------------------
-- FIND VECTOR THRUSTERS
--------------------------------------------------

local thrusters = {}

for _, name in ipairs(peripheral.getNames()) do

    if peripheral.hasType(
        name,
        "liquid_vector_thruster"
    ) then

        local device =
            peripheral.wrap(name)

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

--------------------------------------------------
-- HARDWARE CHECK
--------------------------------------------------

term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "VERTICAL FLIGHT STABILIZATION"
)

print(
    "============================="
)

print()

if not gimbal then

    print(
        "ERROR: gimbal_sensor NOT FOUND"
    )

    return
end

if #thrusters == 0 then

    print(
        "ERROR: liquid_vector_thruster NOT FOUND"
    )

    return
end

print(
    "GIMBAL: " ..
    tostring(gimbalName)
)

print(
    "THRUSTERS: " ..
    tostring(#thrusters)
)

print()

print(
    "Place rocket vertically."
)

print(
    "Nose parallel to Y axis."
)

print()

print(
    "Starting thrust: " ..
    tostring(START_THRUST)
)

print(
    "Maximum thrust: " ..
    tostring(MAX_THRUST)
)

print(
    "Maximum nozzle: +/-" ..
    tostring(MAX_VECTOR)
)

print()

print(
    "Press any key to capture"
)

print(
    "the current attitude."
)

os.pullEvent(
    "key"
)

--------------------------------------------------
-- SET VECTOR
--------------------------------------------------

local function setVector(x, y)

    x =
        clamp(
            x,
            -MAX_VECTOR,
            MAX_VECTOR
        )

    y =
        clamp(
            y,
            -MAX_VECTOR,
            MAX_VECTOR
        )

    for _, entry in ipairs(thrusters) do

        pcall(
            function()

                entry.device.setVector(
                    x,
                    y
                )

            end
        )

    end

end

--------------------------------------------------
-- SET THRUST
--------------------------------------------------

local function setThrust(value)

    value =
        clamp(
            value,
            0,
            1
        )

    for _, entry in ipairs(thrusters) do

        local ok =
            pcall(
                function()

                    entry.device.setThrustNormalized(
                        value
                    )

                end
            )

        if not ok then

            pcall(
                function()

                    entry.device.setPowerNormalized(
                        value
                    )

                end
            )

        end

    end

end

--------------------------------------------------
-- READ SENSORS
--------------------------------------------------

local function readSensors()

    local okAngles,
        angles =
        pcall(
            function()

                return
                    gimbal.getAnglesRad()

            end
        )

    local okRates,
        rates =
        pcall(
            function()

                return
                    gimbal.getAngularRatesRad()

            end
        )

    if not okAngles
        or
        not okRates then

        return nil

    end

    if type(angles) ~= "table"
        or
        type(rates) ~= "table" then

        return nil

    end

    return

        tonumber(
            angles[1]
        ) or 0,

        tonumber(
            angles[2]
        ) or 0,

        tonumber(
            angles[3]
        ) or 0,

        tonumber(
            rates[1]
        ) or 0,

        tonumber(
            rates[2]
        ) or 0,

        tonumber(
            rates[3]
        ) or 0

end

--------------------------------------------------
-- CAPTURE INITIAL ATTITUDE
--------------------------------------------------

local initialA,
    initialB,
    initialC,
    initialRateA,
    initialRateB,
    initialRateC =
    readSensors()

if initialA == nil then

    print(
        "ERROR: SENSOR READ FAILED"
    )

    return
end

--------------------------------------------------
-- TARGET ATTITUDE
--------------------------------------------------

local targetA =
    initialA

local targetB =
    initialB

local targetC =
    initialC

--------------------------------------------------
-- STATE
--------------------------------------------------

local thrust =
    START_THRUST

local running =
    true

local totalTime =
    0

local impulseUntil =
    0

local nextImpulse =
    0

local lastCommandX =
    0

local lastCommandY =
    0

--------------------------------------------------
-- START
--------------------------------------------------

setVector(
    0,
    0
)

setThrust(
    thrust
)

term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "VERTICAL TEST ACTIVE"
)

print(
    "===================="
)

print()

print(
    "TARGET ATTITUDE"
)

print(
    string.format(
        "A = %.3f deg",
        degrees(targetA)
    )
)

print(
    string.format(
        "B = %.3f deg",
        degrees(targetB)
    )
)

print(
    string.format(
        "C = %.3f deg",
        degrees(targetC)
    )
)

print()

print(
    "Q = STOP"
)

--------------------------------------------------
-- TIMER
--------------------------------------------------

local timer =
    os.startTimer(
        UPDATE_INTERVAL
    )

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while running do

    local event,
        parameter =
        os.pullEventRaw()

    --------------------------------------------------
    -- STOP
    --------------------------------------------------

    if event ==
        "key"
        and
        parameter ==
        keys.q then

        running =
            false

    --------------------------------------------------
    -- UPDATE
    --------------------------------------------------

    elseif event ==
        "timer"
        and
        parameter ==
        timer then

        totalTime =
            totalTime +
            UPDATE_INTERVAL

        --------------------------------------------------
        -- SENSOR READ
        --------------------------------------------------

        local currentA,
            currentB,
            currentC,
            rateA,
            rateB,
            rateC =
            readSensors()

        if currentA ~= nil then

            --------------------------------------------------
            -- ATTITUDE ERRORS
            --------------------------------------------------

            local errorA =
                normalizeAngle(
                    targetA -
                    currentA
                )

            local errorB =
                normalizeAngle(
                    targetB -
                    currentB
                )

            local errorC =
                normalizeAngle(
                    targetC -
                    currentC
                )

            --------------------------------------------------
            -- PITCH
            --------------------------------------------------

            local pitchError =
                errorA

            --------------------------------------------------
            -- YAW
            --------------------------------------------------

            local yawError =
                errorC

            --------------------------------------------------
            -- CONTROLLER
            --------------------------------------------------

            local pitchControl =
                (
                    ANGLE_KP *
                    pitchError
                )
                -
                (
                    RATE_KD *
                    rateA
                )

            local yawControl =
                (
                    ANGLE_KP *
                    yawError
                )
                -
                (
                    RATE_KD *
                    rateC
                )

            --------------------------------------------------
            -- MAGNITUDES
            --------------------------------------------------

            local pitchMagnitude =
                math.abs(
                    pitchError
                )

            local yawMagnitude =
                math.abs(
                    yawError
                )

            local pitchRateMagnitude =
                math.abs(
                    rateA
                )

            local yawRateMagnitude =
                math.abs(
                    rateC
                )

            --------------------------------------------------
            -- CURRENT TIME
            --------------------------------------------------

            local now =
                os.clock()

            --------------------------------------------------
            -- DEFAULT
            --------------------------------------------------

            local commandX =
                0

            local commandY =
                0

            --------------------------------------------------
            -- PITCH IMPULSE
            --------------------------------------------------

            if now >= nextImpulse
                and
                pitchMagnitude >
                SMALL_ERROR then

                local impulse =
                    IMPULSE_MIN

                if pitchMagnitude >
                    MEDIUM_ERROR then

                    impulse =
                        0.120
                end

                if pitchMagnitude >
                    LARGE_ERROR then

                    impulse =
                        0.200
                end

                local requested =
                    math.abs(
                        pitchControl
                    )

                if requested >
                    impulse then

                    impulse =
                        math.min(
                            requested,
                            IMPULSE_MAX
                        )

                end

                --------------------------------------------------
                -- HIGH RATE:
                -- BRAKE CURRENT ROTATION
                --------------------------------------------------

                if pitchRateMagnitude >
                    CRITICAL_RATE then

                    commandY =
                        -sign(rateA) *
                        math.min(
                            0.150,
                            pitchRateMagnitude /
                            math.rad(100)
                        )

                elseif pitchRateMagnitude >
                    HIGH_RATE
                    and
                    pitchMagnitude <
                    LARGE_ERROR then

                    commandY =
                        -sign(rateA) *
                        0.100

                else

                    commandY =
                        -sign(
                            pitchControl
                        ) *
                        impulse

                end

            end

            --------------------------------------------------
            -- YAW IMPULSE
            --------------------------------------------------

            if now >= nextImpulse
                and
                yawMagnitude >
                SMALL_ERROR then

                local impulse =
                    IMPULSE_MIN

                if yawMagnitude >
                    MEDIUM_ERROR then

                    impulse =
                        0.120
                end

                if yawMagnitude >
                    LARGE_ERROR then

                    impulse =
                        0.200
                end

                local requested =
                    math.abs(
                        yawControl
                    )

                if requested >
                    impulse then

                    impulse =
                        math.min(
                            requested,
                            IMPULSE_MAX
                        )

                end

                --------------------------------------------------
                -- HIGH RATE:
                -- BRAKE CURRENT ROTATION
                --------------------------------------------------

                if yawRateMagnitude >
                    CRITICAL_RATE then

                    commandX =
                        -sign(rateC) *
                        math.min(
                            0.150,
                            yawRateMagnitude /
                            math.rad(100)
                        )

                elseif yawRateMagnitude >
                    HIGH_RATE
                    and
                    yawMagnitude <
                    LARGE_ERROR then

                    commandX =
                        -sign(rateC) *
                        0.100

                else

                    commandX =
                        -sign(
                            yawControl
                        ) *
                        impulse

                end

            end

            --------------------------------------------------
            -- IMPULSE TIMER
            --------------------------------------------------

            if commandX ~= 0
                or
                commandY ~= 0 then

                impulseUntil =
                    now +
                    IMPULSE_TIME

                nextImpulse =
                    impulseUntil +
                    IMPULSE_COOLDOWN

            end

            --------------------------------------------------
            -- AFTER IMPULSE
            --------------------------------------------------

            if now >= impulseUntil
                and
                now < nextImpulse then

                commandX =
                    0

                commandY =
                    0

            end

            --------------------------------------------------
            -- LIMIT
            --------------------------------------------------

            commandX =
                clamp(
                    commandX,
                    -MAX_VECTOR,
                    MAX_VECTOR
                )

            commandY =
                clamp(
                    commandY,
                    -MAX_VECTOR,
                    MAX_VECTOR
                )

            --------------------------------------------------
            -- SEND NOZZLE COMMAND
            --------------------------------------------------

            setVector(
                commandX,
                commandY
            )

            lastCommandX =
                commandX

            lastCommandY =
                commandY

            --------------------------------------------------
            -- THRUST CONTROL
            --------------------------------------------------

            local attitudeMagnitude =
                math.max(
                    pitchMagnitude,
                    yawMagnitude
                )

            local rateMagnitude =
                math.max(
                    pitchRateMagnitude,
                    yawRateMagnitude
                )

            --------------------------------------------------
            -- INITIAL RAMP
            --------------------------------------------------

            if totalTime <
                5.0 then

                thrust =
                    math.min(
                        MAX_THRUST,
                        thrust +
                        THRUST_RAMP
                    )

            end

            --------------------------------------------------
            -- REDUCE THRUST IF UNSTABLE
            --------------------------------------------------

            if attitudeMagnitude >
                LARGE_ERROR
                or
                rateMagnitude >
                CRITICAL_RATE then

                thrust =
                    math.max(
                        MIN_THRUST,
                        thrust -
                        0.03
                    )

            elseif attitudeMagnitude <
                SMALL_ERROR
                and
                rateMagnitude <
                math.rad(3) then

                thrust =
                    math.min(
                        MAX_THRUST,
                        thrust +
                        0.01
                    )

            end

            --------------------------------------------------
            -- APPLY THRUST
            --------------------------------------------------

            setThrust(
                thrust
            )

            --------------------------------------------------
            -- DISPLAY
            --------------------------------------------------

            term.clear()

            term.setCursorPos(
                1,
                1
            )

            print(
                "VERTICAL FLIGHT TEST"
            )

            print(
                "===================="
            )

            print()

            print(
                string.format(
                    "TIME   %6.2f s",
                    totalTime
                )
            )

            print(
                string.format(
                    "THRUST %6.3f",
                    thrust
                )
            )

            print()

            print(
                string.format(
                    "A %8.3f deg",
                    degrees(currentA)
                )
            )

            print(
                string.format(
                    "B %8.3f deg",
                    degrees(currentB)
                )
            )

            print(
                string.format(
                    "C %8.3f deg",
                    degrees(currentC)
                )
            )

            print()

            print(
                string.format(
                    "ERR A %7.3f deg",
                    degrees(errorA)
                )
            )

            print(
                string.format(
                    "ERR C %7.3f deg",
                    degrees(errorC)
                )
            )

            print()

            print(
                string.format(
                    "RATE A %7.3f",
                    degrees(rateA)
                )
            )

            print(
                string.format(
                    "RATE C %7.3f",
                    degrees(rateC)
                )
            )

            print()

            print(
                string.format(
                    "NOZZLE X %+7.4f",
                    commandX
                )
            )

            print(
                string.format(
                    "NOZZLE Y %+7.4f",
                    commandY
                )
            )

            print()

            print(
                "VECTOR LIMIT 0.250"
            )

            print(
                "THRUST LIMIT 1.000"
            )

            print()

            print(
                "ENGINES " ..
                tostring(
                    #thrusters
                )
            )

            print()

            print(
                "Q = STOP"
            )

        else

            --------------------------------------------------
            -- SENSOR ERROR
            --------------------------------------------------

            setVector(
                0,
                0
            )

            setThrust(
                0
            )

            term.clear()

            term.setCursorPos(
                1,
                1
            )

            print(
                "SENSOR READ ERROR"
            )

        end

        --------------------------------------------------
        -- NEXT TIMER
        --------------------------------------------------

        timer =
            os.startTimer(
                UPDATE_INTERVAL
            )

    end

end

--------------------------------------------------
-- SAFE SHUTDOWN
--------------------------------------------------

setVector(
    0,
    0
)

setThrust(
    0
)

term.clear()

term.setCursorPos(
    1,
    1
)

print(
    "VERTICAL TEST STOPPED"
)

print()

print(
    "THRUST = 0"
)

print(
    "NOZZLE = 0 / 0"
)