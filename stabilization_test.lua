-- Vertical Stabilization Test
-- CC:Tweaked
--
-- Standalone test.
-- NO require()
--
-- PURPOSE:
--   Hold the rocket in the exact attitude it has
--   when the test begins.
--
-- IMPORTANT:
--   Before pressing the start key, place the rocket
--   with its nose parallel to the Y axis.
--
--   The program does NOT control engine thrust.
--   Set thrust manually.
--
-- CONTROLS:
--   Q = stop
--
-- VECTOR:
--   X = yaw correction
--   Y = pitch correction
--
-- MAX VECTOR:
--   0.250
--
-- This test does not use navigation.lua,
-- guidance.lua or actuator.lua.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL =
    0.05


--------------------------------------------------
-- MAXIMUM NOZZLE COMMAND
--------------------------------------------------

local MAX_VECTOR =
    0.250


--------------------------------------------------
-- STARTING ATTITUDE HOLD
--------------------------------------------------

local ANGLE_KP =
    0.050


local RATE_KD =
    0.160


--------------------------------------------------
-- ROLL/YAW RATE DAMPING
--------------------------------------------------

local ROLL_RATE_KD =
    0.100


--------------------------------------------------
-- DEADZONE
--------------------------------------------------

local ANGLE_DEADZONE =
    math.rad(0.15)


--------------------------------------------------
-- HARD RATE PROTECTION
--------------------------------------------------

local HARD_RATE =
    math.rad(30.0)


--------------------------------------------------
-- UTILITIES
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
-- RADIANS -> DEGREES
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
-- ANGLE WRAP
--------------------------------------------------

local function normalizeAngle(
    angle
)

    while angle > math.pi do

        angle =
            angle -
            math.pi * 2

    end


    while angle < -math.pi do

        angle =
            angle +
            math.pi * 2

    end


    return angle

end


--------------------------------------------------
-- FIND GIMBAL SENSOR
--------------------------------------------------

local gimbal =
    nil


local gimbalName =
    nil


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

            gimbalName =
                name

            break

        end

    end

end


--------------------------------------------------
-- FIND VECTOR THRUSTERS
--------------------------------------------------

local thrusters =
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
    "VERTICAL STABILIZATION TEST"
)


print(
    "============================"
)


print()


if not gimbal then

    print(
        "ERROR: GIMBAL SENSOR NOT FOUND"
    )

    return

end


if #thrusters == 0 then

    print(
        "ERROR: VECTOR THRUSTERS NOT FOUND"
    )

    return

end


print(
    "GIMBAL: " ..
    tostring(
        gimbalName
    )
)


print(
    "THRUSTERS: " ..
    tostring(
        #thrusters
    )
)


print()


print(
    "Set rocket vertically first."
)


print(
    "Nose must be parallel to Y axis."
)


print()


print(
    "Recommended thrust: 0.2"
)


print()


print(
    "Press any key to capture"
)


print(
    "the current orientation."
)


os.pullEvent(
    "key"
)


--------------------------------------------------
-- VECTOR FUNCTION
--------------------------------------------------

local function setVector(
    x,
    y
)

    local success =
        0


    for _, entry in ipairs(
        thrusters
    ) do

        local ok =
            pcall(
                function()

                    entry.device.setVector(
                        x,
                        y
                    )

                end
            )


        if ok then

            success =
                success + 1

        end

    end


    return success

end


--------------------------------------------------
-- INITIAL SENSOR READ
--------------------------------------------------

local okAngles,
    initialAngles =
    pcall(
        function()

            return
                gimbal.getAnglesRad()

        end
    )


local okRates,
    initialRates =
    pcall(
        function()

            return
                gimbal.getAngularRatesRad()

        end
    )


if not okAngles
    or
    type(initialAngles) ~=
        "table" then

    print(
        "ERROR: getAnglesRad() failed"
    )

    return

end


if not okRates
    or
    type(initialRates) ~=
        "table" then

    print(
        "ERROR: getAngularRatesRad() failed"
    )

    return

end


--------------------------------------------------
-- CAPTURE INITIAL ATTITUDE
--
-- We hold the exact orientation that the user
-- placed the rocket in.
--
-- This avoids assumptions about whether the sensor
-- reports vertical as 0, 90 or another value.
--------------------------------------------------

local targetA =
    tonumber(
        initialAngles[1]
    )
    or
    0


local targetB =
    tonumber(
        initialAngles[2]
    )
    or
    0


local targetC =
    tonumber(
        initialAngles[3]
    )
    or
    0


--------------------------------------------------
-- START
--------------------------------------------------

setVector(
    0,
    0
)


term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "STABILIZATION ACTIVE"
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
        "A %8.3f deg",
        degrees(targetA)
    )
)


print(
    string.format(
        "B %8.3f deg",
        degrees(targetB)
    )
)


print(
    string.format(
        "C %8.3f deg",
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


local running =
    true


--------------------------------------------------
-- LOOP
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
    -- TIMER
    --------------------------------------------------

    elseif event ==
        "timer"
        and
        parameter ==
        timer then

        --------------------------------------------------
        -- READ ANGLES
        --------------------------------------------------

        local anglesOk,
            angles =
            pcall(
                function()

                    return
                        gimbal.getAnglesRad()

                end
            )


        --------------------------------------------------
        -- READ RATES
        --------------------------------------------------

        local ratesOk,
            rates =
            pcall(
                function()

                    return
                        gimbal.getAngularRatesRad()

                end
            )


        if anglesOk
            and
            ratesOk
            and
            type(angles) ==
                "table"
            and
            type(rates) ==
                "table" then

            --------------------------------------------------
            -- CURRENT ATTITUDE
            --------------------------------------------------

            local angleA =
                tonumber(
                    angles[1]
                )
                or
                0


            local angleB =
                tonumber(
                    angles[2]
                )
                or
                0


            local angleC =
                tonumber(
                    angles[3]
                )
                or
                0


            --------------------------------------------------
            -- CURRENT RATES
            --------------------------------------------------

            local rateA =
                tonumber(
                    rates[1]
                )
                or
                0


            local rateB =
                tonumber(
                    rates[2]
                )
                or
                0


            local rateC =
                tonumber(
                    rates[3]
                )
                or
                0


            --------------------------------------------------
            -- ATTITUDE ERRORS
            --------------------------------------------------

            local errorA =
                normalizeAngle(
                    targetA -
                    angleA
                )


            local errorB =
                normalizeAngle(
                    targetB -
                    angleB
                )


            local errorC =
                normalizeAngle(
                    targetC -
                    angleC
                )


            --------------------------------------------------
            -- SMALL DEADZONE
            --------------------------------------------------

            if math.abs(
                errorA
            ) <
            ANGLE_DEADZONE then

                errorA =
                    0

            end


            if math.abs(
                errorB
            ) <
            ANGLE_DEADZONE then

                errorB =
                    0

            end


            if math.abs(
                errorC
            ) <
            ANGLE_DEADZONE then

                errorC =
                    0

            end


            --------------------------------------------------
            -- PITCH CONTROL
            --
            -- A is treated as the primary pitch axis.
            --------------------------------------------------

            local pitchP =
                ANGLE_KP *
                errorA


            local pitchD =
                -RATE_KD *
                rateA


            local pitchCommand =
                pitchP +
                pitchD


            --------------------------------------------------
            -- YAW / HEADING CONTROL
            --
            -- C is used as the yaw axis.
            --------------------------------------------------

            local yawP =
                ANGLE_KP *
                errorC


            local yawD =
                -RATE_KD *
                rateC


            local yawCommand =
                yawP +
                yawD


            --------------------------------------------------
            -- EXTRA RATE DAMPING
            --------------------------------------------------

            if math.abs(
                rateA
            ) >
            HARD_RATE then

                pitchCommand =
                    pitchCommand *
                    0.35

            end


            if math.abs(
                rateC
            ) >
            HARD_RATE then

                yawCommand =
                    yawCommand *
                    0.35

            end


            --------------------------------------------------
            -- PHYSICAL SIGN
            --
            -- Based on your bench observation:
            --
            -- nozzle left
            --   -> tail moves up
            --   -> nose rotates left
            --
            -- Therefore the physical response is not
            -- assumed to be the same sign as the error.
            --
            -- These signs are kept explicit for testing.
            --------------------------------------------------

            local commandX =
                -yawCommand


            local commandY =
                -pitchCommand


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
            -- SEND
            --------------------------------------------------

            local engines =
                setVector(
                    commandX,
                    commandY
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
                "VERTICAL STABILIZATION"
            )


            print(
                "======================="
            )


            print()


            print(
                string.format(
                    "A     %8.3f deg",
                    degrees(angleA)
                )
            )


            print(
                string.format(
                    "B     %8.3f deg",
                    degrees(angleB)
                )
            )


            print(
                string.format(
                    "C     %8.3f deg",
                    degrees(angleC)
                )
            )


            print()


            print(
                string.format(
                    "ERR A %8.3f deg",
                    degrees(errorA)
                )
            )


            print(
                string.format(
                    "ERR B %8.3f deg",
                    degrees(errorB)
                )
            )


            print(
                string.format(
                    "ERR C %8.3f deg",
                    degrees(errorC)
                )
            )


            print()


            print(
                string.format(
                    "RATE A %7.3f deg/s",
                    degrees(rateA)
                )
            )


            print(
                string.format(
                    "RATE B %7.3f deg/s",
                    degrees(rateB)
                )
            )


            print(
                string.format(
                    "RATE C %7.3f deg/s",
                    degrees(rateC)
                )
            )


            print()


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


            print()


            print(
                "ENGINES " ..
                tostring(
                    engines
                ) ..
                "/" ..
                tostring(
                    #thrusters
                )
            )


            print()


            print(
                "MAX VECTOR 0.250"
            )


            print()


            print(
                "Q = STOP"
            )

        else

            setVector(
                0,
                0
            )


            term.clear()

            term.setCursorPos(
                1,
                1
            )


            print(
                "GIMBAL SENSOR READ ERROR"
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


term.clear()

term.setCursorPos(
    1,
    1
)


print(
    "STABILIZATION TEST STOPPED"
)


print()


print(
    "All nozzles returned to 0 / 0."
)