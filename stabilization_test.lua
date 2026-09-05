-- VERTICAL IMPULSE STABILIZATION TEST
-- CC:Tweaked
--
-- STANDALONE
-- NO require()
--
-- Основная идея:
--   1. Двигатели дают постоянную тягу.
--   2. Для коррекции ракеты сопло кратковременно
--      отклоняется на большой угол.
--   3. После короткого импульса сопло возвращается в 0.
--
-- Q = STOP

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

--------------------------------------------------
-- MAIN THRUST
--------------------------------------------------

-- Основная тяга двигателя.
-- Диапазон 0.0 .. 1.0

local TARGET_THRUST = 0.30

-- Скорость набора основной тяги
local THRUST_RAMP = 0.02

--------------------------------------------------
-- NOZZLE
--------------------------------------------------

-- Максимальное физическое отклонение сопла
local MAX_VECTOR = 0.250

--------------------------------------------------
-- IMPULSE CONTROL
--------------------------------------------------

-- Минимальная ошибка, при которой вообще начинается
-- боковая коррекция.
local ERROR_DEADZONE = math.rad(1.5)

-- Ошибка для сильного импульса
local LARGE_ERROR = math.rad(5.0)

-- Очень большая ошибка
local VERY_LARGE_ERROR = math.rad(10.0)

-- Короткий боковой импульс
local IMPULSE_TIME = 0.10

-- Минимальная пауза между импульсами
local IMPULSE_COOLDOWN = 0.20

--------------------------------------------------
-- IMPULSE STRENGTH
--------------------------------------------------

-- Небольшая коррекция
local SMALL_IMPULSE = 0.080

-- Средняя коррекция
local MEDIUM_IMPULSE = 0.150

-- Сильная коррекция
local LARGE_IMPULSE = 0.200

-- Максимально допустимый импульс
local MAX_IMPULSE = 0.250

--------------------------------------------------
-- ANGULAR RATE
--------------------------------------------------

-- Если вращение уже довольно быстрое в сторону ошибки,
-- новый импульс не даём.
local HOLD_RATE = math.rad(8.0)

-- При этой скорости считаем вращение опасным.
local CRITICAL_RATE = math.rad(20.0)

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
-- FIND GIMBAL
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
-- FIND THRUSTERS
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
term.setCursorPos(1, 1)

print("VERTICAL IMPULSE STABILIZATION")
print("==============================")
print()

if not gimbal then

    print("ERROR: gimbal_sensor NOT FOUND")

    return
end

if #thrusters == 0 then

    print("ERROR: liquid_vector_thruster NOT FOUND")

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
    "TARGET THRUST: " ..
    string.format(
        "%.3f",
        TARGET_THRUST
    )
)

print(
    "MAX NOZZLE: +/-" ..
    string.format(
        "%.3f",
        MAX_VECTOR
    )
)

print()

print("Place rocket vertically.")
print("Nose parallel to Y axis.")
print()

print("Press any key to capture attitude.")

os.pullEvent("key")

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
-- READ GIMBAL
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

    print("ERROR: SENSOR READ FAILED")

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

local running =
    true

local totalTime =
    0

local thrust =
    0

--------------------------------------------------
-- IMPULSE STATE
--------------------------------------------------

local impulseActive =
    false

local impulseUntil =
    0

local nextImpulseAllowed =
    0

local currentImpulseX =
    0

local currentImpulseY =
    0

--------------------------------------------------
-- START
--------------------------------------------------

setVector(
    0,
    0
)

setThrust(
    0
)

term.clear()
term.setCursorPos(1, 1)

print("VERTICAL IMPULSE TEST")
print("=====================")
print()

print(
    string.format(
        "TARGET A %.3f deg",
        degrees(targetA)
    )
)

print(
    string.format(
        "TARGET B %.3f deg",
        degrees(targetB)
    )
)

print(
    string.format(
        "TARGET C %.3f deg",
        degrees(targetC)
    )
)

print()

print("Main thrust will ramp to:")
print(
    string.format(
        "%.3f",
        TARGET_THRUST
    )
)

print()

print("Q = STOP")

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
        -- THRUST RAMP
        --------------------------------------------------

        if thrust < TARGET_THRUST then

            thrust =
                math.min(
                    TARGET_THRUST,
                    thrust + THRUST_RAMP
                )

            setThrust(
                thrust
            )
        end

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
            -- ERROR
            --------------------------------------------------

            local errorA =
                normalizeAngle(
                    targetA -
                    currentA
                )

            local errorC =
                normalizeAngle(
                    targetC -
                    currentC
                )

            --------------------------------------------------
            -- MAGNITUDE
            --------------------------------------------------

            local absA =
                math.abs(errorA)

            local absC =
                math.abs(errorC)

            --------------------------------------------------
            -- CURRENT TIME
            --------------------------------------------------

            local now =
                os.clock()

            --------------------------------------------------
            -- ACTIVE IMPULSE
            --------------------------------------------------

            if impulseActive then

                --------------------------------------------------
                -- Keep strong side thrust for a SHORT
                -- fixed period.
                --------------------------------------------------

                if now < impulseUntil then

                    setVector(
                        currentImpulseX,
                        currentImpulseY
                    )

                else

                    --------------------------------------------------
                    -- IMPORTANT:
                    -- impulse is finished.
                    -- Return nozzle to neutral.
                    --------------------------------------------------

                    impulseActive =
                        false

                    currentImpulseX =
                        0

                    currentImpulseY =
                        0

                    setVector(
                        0,
                        0
                    )

                    nextImpulseAllowed =
                        now +
                        IMPULSE_COOLDOWN
                end

            --------------------------------------------------
            -- NO ACTIVE IMPULSE
            --------------------------------------------------

            else

                setVector(
                    0,
                    0
                )

                --------------------------------------------------
                -- Only create a new pulse after cooldown.
                --------------------------------------------------

                if now >= nextImpulseAllowed then

                    local impulseX =
                        0

                    local impulseY =
                        0

                    --------------------------------------------------
                    -- CHOOSE DOMINANT AXIS
                    --
                    -- We intentionally control only ONE axis
                    -- at a time.
                    --------------------------------------------------

                    local controlAxis =
                        nil

                    if absA >
                        ERROR_DEADZONE
                        and
                        absA >= absC then

                        controlAxis =
                            "PITCH"

                    elseif absC >
                        ERROR_DEADZONE then

                        controlAxis =
                            "YAW"

                    end

                    --------------------------------------------------
                    -- PITCH IMPULSE
                    --------------------------------------------------

                    if controlAxis ==
                        "PITCH" then

                        local direction =
                            sign(errorA)

                        --------------------------------------------------
                        -- If rocket is already rotating toward the
                        -- target quickly, DO NOT add another pulse.
                        --
                        -- This prevents oscillation.
                        --------------------------------------------------

                        local rateCorrectDirection =
                            rateA *
                            errorA

                        --------------------------------------------------
                        -- Critical rotation:
                        -- apply a short braking impulse.
                        --------------------------------------------------

                        if math.abs(rateA) >
                            CRITICAL_RATE then

                            impulseY =
                                -sign(rateA) *
                                SMALL_IMPULSE

                        elseif
                            rateCorrectDirection > 0
                            and
                            math.abs(rateA) >
                            HOLD_RATE then

                            --------------------------------------------------
                            -- Already rotating in correct direction.
                            -- Let it continue naturally.
                            --------------------------------------------------

                            impulseY =
                                0

                        else

                            --------------------------------------------------
                            -- Select impulse strength from error.
                            --------------------------------------------------

                            local magnitude =
                                SMALL_IMPULSE

                            if absA >
                                LARGE_ERROR then

                                magnitude =
                                    LARGE_IMPULSE

                            elseif absA >
                                math.rad(2.5) then

                                magnitude =
                                    MEDIUM_IMPULSE
                            end

                            if absA >
                                VERY_LARGE_ERROR then

                                magnitude =
                                    MAX_IMPULSE
                            end

                            impulseY =
                                direction *
                                magnitude
                        end

                    --------------------------------------------------
                    -- YAW IMPULSE
                    --------------------------------------------------

                    elseif controlAxis ==
                        "YAW" then

                        local direction =
                            sign(errorC)

                        local rateCorrectDirection =
                            rateC *
                            errorC

                        --------------------------------------------------
                        -- Critical rotation:
                        -- braking pulse.
                        --------------------------------------------------

                        if math.abs(rateC) >
                            CRITICAL_RATE then

                            impulseX =
                                -sign(rateC) *
                                SMALL_IMPULSE

                        elseif
                            rateCorrectDirection > 0
                            and
                            math.abs(rateC) >
                            HOLD_RATE then

                            impulseX =
                                0

                        else

                            local magnitude =
                                SMALL_IMPULSE

                            if absC >
                                LARGE_ERROR then

                                magnitude =
                                    LARGE_IMPULSE

                            elseif absC >
                                math.rad(2.5) then

                                magnitude =
                                    MEDIUM_IMPULSE
                            end

                            if absC >
                                VERY_LARGE_ERROR then

                                magnitude =
                                    MAX_IMPULSE
                            end

                            impulseX =
                                direction *
                                magnitude
                        end
                    end

                    --------------------------------------------------
                    -- START IMPULSE
                    --------------------------------------------------

                    if impulseX ~= 0
                        or
                        impulseY ~= 0 then

                        currentImpulseX =
                            clamp(
                                impulseX,
                                -MAX_VECTOR,
                                MAX_VECTOR
                            )

                        currentImpulseY =
                            clamp(
                                impulseY,
                                -MAX_VECTOR,
                                MAX_VECTOR
                            )

                        impulseActive =
                            true

                        impulseUntil =
                            now +
                            IMPULSE_TIME

                        setVector(
                            currentImpulseX,
                            currentImpulseY
                        )
                    end
                end
            end

            --------------------------------------------------
            -- DISPLAY
            --------------------------------------------------

            term.clear()
            term.setCursorPos(
                1,
                1
            )

            print("VERTICAL IMPULSE TEST")
            print("=====================")
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
                    "A      %8.3f deg",
                    degrees(currentA)
                )
            )

            print(
                string.format(
                    "C      %8.3f deg",
                    degrees(currentC)
                )
            )

            print()

            print(
                string.format(
                    "ERR A  %8.3f deg",
                    degrees(errorA)
                )
            )

            print(
                string.format(
                    "ERR C  %8.3f deg",
                    degrees(errorC)
                )
            )

            print()

            print(
                string.format(
                    "RATE A %8.3f",
                    degrees(rateA)
                )
            )

            print(
                string.format(
                    "RATE C %8.3f",
                    degrees(rateC)
                )
            )

            print()

            print(
                string.format(
                    "NOZZLE X %+7.3f",
                    currentImpulseX
                )
            )

            print(
                string.format(
                    "NOZZLE Y %+7.3f",
                    currentImpulseY
                )
            )

            print()

            if impulseActive then

                print(
                    "IMPULSE: ACTIVE"
                )

            else

                print(
                    "IMPULSE: READY"
                )
            end

            print()

            print(
                "MAX VECTOR 0.250"
            )

            print(
                "THRUST 0.000..1.000"
            )

            print()

            print(
                "ENGINES " ..
                tostring(
                    #thrusters
                )
            )

            print()

            print("Q = STOP")

        else

            --------------------------------------------------
            -- SENSOR FAILURE
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

            print("SENSOR READ ERROR")
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

print("TEST STOPPED")