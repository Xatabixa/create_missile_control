-- Vertical Stabilization Test
-- CC:Tweaked
--
-- Standalone test.
-- NO require()
--
-- Controls:
--   Q = stop
--
-- Engine thrust is NOT controlled here.
-- Set thrust manually on the engine controller.

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local UPDATE_INTERVAL = 0.05

local MAX_VECTOR = 0.100

local PITCH_KP = 0.025
local PITCH_KD = 0.100

local YAW_KP = 0.020
local YAW_KD = 0.080

--------------------------------------------------
-- FUNCTIONS
--------------------------------------------------

local function clamp(value, minValue, maxValue)

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value

end


local function degrees(rad)

    return rad * 180 / math.pi

end


--------------------------------------------------
-- FIND GIMBAL SENSOR
--------------------------------------------------

local gimbal = nil
local gimbalName = nil

for _, name in ipairs(peripheral.getNames()) do

    if peripheral.hasType(name, "gimbal_sensor") then

        gimbal = peripheral.wrap(name)
        gimbalName = name
        break

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
term.setCursorPos(1, 1)

print("VERTICAL STABILIZATION TEST")
print("============================")
print()

if not gimbal then

    print("ERROR: gimbal_sensor not found")
    return

end


if #thrusters == 0 then

    print("ERROR: liquid_vector_thruster not found")
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
print("Set engine thrust manually.")
print("Recommended thrust: 0.2")
print()
print("Press any key to start.")

os.pullEvent("key")


--------------------------------------------------
-- NEUTRAL
--------------------------------------------------

local function setVector(x, y)

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


setVector(0, 0)


--------------------------------------------------
-- START
--------------------------------------------------

term.clear()
term.setCursorPos(1, 1)

print("VERTICAL STABILIZATION ACTIVE")
print("==============================")
print()
print("Q = STOP")
print()

--------------------------------------------------
-- TIMER
--------------------------------------------------

local timer =
    os.startTimer(
        UPDATE_INTERVAL
    )


local running = true

--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

while running do

    local event, a =
        os.pullEventRaw()


    --------------------------------------------------
    -- STOP
    --------------------------------------------------

    if event == "key"
        and
        a == keys.q then

        running = false


    --------------------------------------------------
    -- UPDATE
    --------------------------------------------------

    elseif event == "timer"
        and
        a == timer then

        --------------------------------------------------
        -- READ ANGLES
        --------------------------------------------------

        local okAngles,
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

        local okRates,
            rates =
            pcall(
                function()

                    return
                        gimbal.getAngularRatesRad()

                end
            )


        if okAngles
            and
            okRates
            and
            type(angles) == "table"
            and
            type(rates) == "table" then

            --------------------------------------------------
            -- SENSOR AXES
            --
            -- According to the current navigation setup:
            --
            -- angles[1] = pitch
            -- angles[2] = roll
            --
            -- rates[1] = X
            -- rates[2] = Y
            -- rates[3] = Z
            --------------------------------------------------

            local pitch =
                tonumber(
                    angles[1]
                )
                or
                0


            local roll =
                tonumber(
                    angles[2]
                )
                or
                0


            local pitchRate =
                tonumber(
                    rates[1]
                )
                or
                0


            local rollRate =
                tonumber(
                    rates[2]
                )
                or
                0


            local yawRate =
                tonumber(
                    rates[3]
                )
                or
                0


            --------------------------------------------------
            -- PITCH STABILIZATION
            --------------------------------------------------

            local pitchP =
                PITCH_KP *
                pitch


            local pitchD =
                -PITCH_KD *
                pitchRate


            local pitchOutput =
                pitchP +
                pitchD


            --------------------------------------------------
            -- YAW RATE DAMPING
            --
            -- We don't have a reliable absolute yaw angle
            -- in this test, so yaw uses rate damping only.
            --------------------------------------------------

            local yawOutput =
                -YAW_KD *
                yawRate


            --------------------------------------------------
            -- COMMAND
            --------------------------------------------------

            local commandX =
                clamp(
                    -yawOutput,
                    -MAX_VECTOR,
                    MAX_VECTOR
                )


            local commandY =
                clamp(
                    -pitchOutput,
                    -MAX_VECTOR,
                    MAX_VECTOR
                )


            --------------------------------------------------
            -- SEND TO ALL THRUSTERS
            --------------------------------------------------

            setVector(
                commandX,
                commandY
            )


            --------------------------------------------------
            -- DISPLAY
            --------------------------------------------------

            term.clear()
            term.setCursorPos(1, 1)

            print(
                "VERTICAL STABILIZATION"
            )

            print(
                "======================="
            )

            print()

            print(
                string.format(
                    "PITCH %8.3f deg",
                    degrees(pitch)
                )
            )

            print(
                string.format(
                    "ROLL  %8.3f deg",
                    degrees(roll)
                )
            )

            print()

            print(
                string.format(
                    "PITCH RATE %8.3f deg/s",
                    degrees(pitchRate)
                )
            )

            print(
                string.format(
                    "ROLL RATE  %8.3f deg/s",
                    degrees(rollRate)
                )
            )

            print(
                string.format(
                    "YAW RATE   %8.3f deg/s",
                    degrees(yawRate)
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
                "ENGINES: " ..
                tostring(#thrusters)
            )

            print()

            print("Q = STOP")

        else

            setVector(0, 0)

            term.clear()
            term.setCursorPos(1, 1)

            print(
                "GIMBAL SENSOR READ ERROR"
            )

        end


        --------------------------------------------------
        -- NEXT UPDATE
        --------------------------------------------------

        timer =
            os.startTimer(
                UPDATE_INTERVAL
            )

    end

end


--------------------------------------------------
-- SAFE STOP
--------------------------------------------------

setVector(0, 0)


term.clear()
term.setCursorPos(1, 1)

print(
    "STABILIZATION TEST STOPPED"
)

print()
print(
    "All nozzles returned to 0 / 0."
)