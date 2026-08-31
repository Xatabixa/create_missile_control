-- Vertical Stabilization Test
-- CC:Tweaked
--
-- Completely standalone.
-- NO require()
--
-- Purpose:
--   Test whether the rocket can keep its attitude
--   approximately vertical while the engine is running.
--
-- IMPORTANT:
--   This program does NOT control engine power.
--   Set thrust separately.
--
-- Controls:
--   Q = stop test and return all nozzles to neutral
--
-- Current control model:
--
--   command X -> yaw correction
--   command Y -> pitch correction
--
-- Roll is intentionally not controlled here because
-- the current vector-thruster interface gives us only
-- the common X/Y command.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL =
    0.05


--------------------------------------------------
-- TEST LIMIT
--
-- This is the maximum vector command used by the
-- stabilization test.
--------------------------------------------------

local MAX_VECTOR =
    0.100


--------------------------------------------------
-- PID / PD
--------------------------------------------------

local YAW_KP =
    0.020


local PITCH_KP =
    0.025


local YAW_KD =
    0.080


local PITCH_KD =
    0.100


--------------------------------------------------
-- ANGLE DEADZONE
--------------------------------------------------

local YAW_DEADZONE =
    math.rad(0.25)


local PITCH_DEADZONE =
    math.rad(0.25)


--------------------------------------------------
-- RATE LIMIT
--
-- Above this angular rate the stabilization command
-- is reduced rather than amplified.
--------------------------------------------------

local MAX_SAFE_RATE =
    math.rad(25)


--------------------------------------------------
-- HELPERS
--------------------------------------------------

local function clamp(
    value,
    minimum,
    maximum
)

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value

end


--------------------------------------------------
-- PERIPHERAL FIND
--------------------------------------------------

local function findFirstType(
    peripheralType
)

    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            peripheralType
        ) then

            if peripheral.isPresent(
                name
            ) then

                local device =
                    peripheral.wrap(
                        name
                    )

                if device then

                    return device,
                        name

                end

            end

        end

    end

    return nil, nil

end


--------------------------------------------------
-- FIND ALL VECTOR THRUSTERS
--------------------------------------------------

local function findThrusters()

    local result =
        {}


    for _, name in ipairs(
        peripheral.getNames()
    ) do

        if peripheral.hasType(
            name,
            "liquid_vector_thruster"
        ) then

            local device =
                peripheral.wrap(
                    name
                )


            if device then

                table.insert(
                    result,
                    {
                        name =
                            name,

                        device =
                            device
                    }
                )

            end

        end

    end


    return result

end


--------------------------------------------------
-- SET VECTOR
--------------------------------------------------

local function setThrusterVector(
    entry,
    x,
    y
)

    local device =
        entry.device


    local ok =
        pcall(
            function()

                device.setVector(
                    x,
                    y
                )

            end
        )


    return ok

end


--------------------------------------------------
-- SET ALL THRUSTERS
--------------------------------------------------

local function setAllVectors(
    thrusters,
    x,
    y
)

    local successful =
        0


    for _, entry in ipairs(
        thrusters
    ) do

        if setThrusterVector(
            entry,
            x,
            y
        ) then

            successful =
                successful + 1

        end

    end


    return successful

end


--------------------------------------------------
-- READ GIMBAL ANGLES
--------------------------------------------------

local function readAngles(
    sensor
)

    local ok,
        values =
        pcall(
            function()

                return
                    sensor.getAnglesRad()

            end
        )


    if not ok
        or
        type(values) ~= "table" then

        return nil,
            nil

    end


    local pitch =
        tonumber(
            values[1]
        )
        or
        0


    local roll =
        tonumber(
            values[2]
        )
        or
        0


    return pitch,
        roll

end


--------------------------------------------------
-- READ ANGULAR RATES
--------------------------------------------------

local function readRates(
    sensor
)

    local ok,
        values =
        pcall(
            function()

                return
                    sensor.getAngularRatesRad()

            end
        )


    if not ok
        or
        type(values) ~= "table" then

        return nil,
            nil,
            nil

    end


    local rateX =
        tonumber(
            values[1]
        )
        or
        0


    local rateY =
        tonumber(
            values[2]
        )
        or
        0


    local rateZ =
        tonumber(
            values[3]
        )
        or
        0


    return rateX,
        rateY,
        rateZ

end


--------------------------------------------------
-- DEGREES
--------------------------------------------------

local function degrees(
    radians
)

    return
        radians *
        180 /
        math.pi

end


--------------------------------------------------
-- SCREEN
--------------------------------------------------

local function draw(
    pitch,
    yaw,
    ratePitch,
    rateYaw,
    commandX,
    commandY,
    engines,
    running
)

    term.clear()

    term.setCursorPos(
        1,
        1
    )


    print(
        "VERTICAL STABILIZATION TEST"
    )


    print(
        "============================"
    )


    if running then

        print(
            "STATUS: RUNNING"
        )

    else

        print(
            "STATUS: STOPPED"
        )

    end


    print(
        ""
    )


    print(
        string.format(
            "PITCH %7.3f deg",
            pitch
        )
    )


    print(
        string.format(
            "YAW   %7.3f deg",
            yaw
        )
    )


    print(
        ""
    )


    print(
        string.format(
            "PITCH RATE %7.3f deg/s",
            ratePitch
        )
    )


    print(
        string.format(
            "YAW RATE   %7.3f deg/s",
            rateYaw
        )
    )


    print(
        ""
    )


    print(
        string.format(
            "CMD X %8.4f",
            commandX
        )
    )


    print(
        string.format(
            "CMD Y %8.4f",
            commandY
        )
    )


    print(
        ""
    )


    print(
        "ENGINES " ..
        tostring(
            engines
        ) ..
        "/4"
    )


    print(
        ""
    )


    print(
        "TARGET:"
    )


    print(
        "PITCH 0.000 deg"
    )


    print(
        "YAW   0.000 deg"
    )


    print(
        ""
    )


    print(
        "Q = STOP"
    )

end


--------------------------------------------------
-- MAIN
--------------------------------------------------

local gimbalSensor,
    gimbalName =
    findFirstType(
        "gimbal_sensor"
    )


local thrusters =
    findThrusters()


--------------------------------------------------
-- CHECK HARDWARE
--------------------------------------------------

if not gimbalSensor then

    term.clear()

    term.setCursorPos(
        1,
        1
    )


    print(
        "ERROR: GIMBAL SENSOR NOT FOUND"
    )


    print(
        ""
    )


    print(
        "Required peripheral:"
    )


    print(
        "gimbal_sensor"
    )


    return

end


if #thrusters == 0 then

    term.clear()

    term.setCursorPos(
        1,
        1
    )


    print(
        "ERROR: VECTOR THRUSTERS NOT FOUND"
    )


    return

end


--------------------------------------------------
-- START
--------------------------------------------------

term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "VERTICAL STABILIZATION TEST"
)


print(
    "============================"
)


print(
    ""
)


print(
    "GIMBAL:"
)


print(
    gimbalName
)


print(
    ""
)


print(
    "THRUSTERS FOUND: " ..
    tostring(
        #thrusters
    )
)


print(
    ""
)


print(
    "Set engine thrust manually."
)


print(
    "Recommended: 0.2 initially."
)


print(
    ""
)


print(
    "Press any key to START."
)


os.pullEvent(
    "key"
)


--------------------------------------------------
-- STABILIZATION LOOP
--------------------------------------------------

local running =
    true


local commandX =
    0


local commandY =
    0


local lastPitch =
    0


local lastYaw =
    0


local started =
    os.clock()


while running do

    --------------------------------------------------
    -- INPUT CHECK
    --------------------------------------------------

    local event,
        key =
        os.pullEventRaw()


    --------------------------------------------------
    -- STOP
    --------------------------------------------------

    if event ==
        "key"
        and
        key ==
        keys.q then

        running =
            false


        break

    end


    --------------------------------------------------
    -- SENSOR
    --------------------------------------------------

    local pitch,
        roll =
        readAngles(
            gimbalSensor
        )


    local rateX,
        rateY,
        rateZ =
        readRates(
            gimbalSensor
        )


    if pitch == nil then

        commandX =
            0


        commandY =
            0


        setAllVectors(
            thrusters,
            0,
            0
        )


        draw(
            0,
            0,
            0,
            0,
            0,
            0,
            #thrusters,
            true
        )


        print(
            ""
        )


        print(
            "GIMBAL READ ERROR"
        )


        sleep(
            0.2
        )


    else

        --------------------------------------------------
        -- YAW
        --
        -- The current rocket normally starts with
        -- yaw approximately zero.
        --
        -- We use gimbal rate Z for damping.
        --------------------------------------------------

        local yaw =
            0


        local yawRate =
            rateZ
            or
            0


        --------------------------------------------------
        -- PITCH
        --
        -- getAnglesRad()[1]
        -- getAngularRatesRad()[1]
        --------------------------------------------------

        local pitchRate =
            rateX
            or
            0


        --------------------------------------------------
        -- DEADZONE
        --------------------------------------------------

        local effectiveYaw =
            yaw


        local effectivePitch =
            pitch


        if math.abs(
            effectiveYaw
        ) <
        YAW_DEADZONE then

            effectiveYaw =
                0

        end


        if math.abs(
            effectivePitch
        ) <
        PITCH_DEADZONE then

            effectivePitch =
                0

        end


        --------------------------------------------------
        -- PITCH CONTROL
        --------------------------------------------------

        local pitchP =
            PITCH_KP *
            effectivePitch


        local pitchD =
            -PITCH_KD *
            pitchRate


        local pitchOutput =
            pitchP +
            pitchD


        --------------------------------------------------
        -- YAW CONTROL
        --------------------------------------------------

        local yawP =
            YAW_KP *
            effectiveYaw


        local yawD =
            -YAW_KD *
            yawRate


        local yawOutput =
            yawP +
            yawD


        --------------------------------------------------
        -- VERY HIGH RATE PROTECTION
        --------------------------------------------------

        if math.abs(
            pitchRate
        ) >
        MAX_SAFE_RATE then

            pitchOutput =
                pitchOutput *
                0.25

        end


        if math.abs(
            yawRate
        ) >
        MAX_SAFE_RATE then

            yawOutput =
                yawOutput *
                0.25

        end


        --------------------------------------------------
        -- PHYSICAL SIGNS
        --
        -- These are intentionally explicit so they are
        -- easy to reverse after the first test if the
        -- rocket reacts in the opposite direction.
        --------------------------------------------------

        local desiredX =
            -yawOutput


        local desiredY =
            -pitchOutput


        --------------------------------------------------
        -- LIMIT
        --------------------------------------------------

        desiredX =
            clamp(
                desiredX,
                -MAX_VECTOR,
                MAX_VECTOR
            )


        desiredY =
            clamp(
                desiredY,
                -MAX_VECTOR,
                MAX_VECTOR
            )


        --------------------------------------------------
        -- COMMAND
        --------------------------------------------------

        commandX =
            desiredX


        commandY =
            desiredY


        --------------------------------------------------
        -- APPLY
        --------------------------------------------------

        setAllVectors(
            thrusters,
            commandX,
            commandY
        )


        --------------------------------------------------
        -- DISPLAY
        --
        -- The local variable "yaw" is kept as zero in
        -- this standalone test because the current
        -- gimbal API does not expose a separate heading
        -- angle here.
        --
        -- rateZ is still used for damping.
        --------------------------------------------------

        draw(
            degrees(
                pitch
            ),
            0,
            degrees(
                pitchRate
            ),
            degrees(
                yawRate
            ),
            commandX,
            commandY,
            #thrusters,
            true
        )

    end


    --------------------------------------------------
    -- LOOP RATE
    --------------------------------------------------

    sleep(
        UPDATE_INTERVAL
    )

end


--------------------------------------------------
-- SAFE STOP
--------------------------------------------------

setAllVectors(
    thrusters,
    0,
    0
)


term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "VERTICAL STABILIZATION TEST"
)


print(
    "============================"
)


print(
    ""
)


print(
    "TEST STOPPED"
)


print(
    ""
)


print(
    "All nozzles returned to 0 / 0."
)
